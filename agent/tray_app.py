"""
MK Restaurants Local Agent - Tray Application (v2.3)
Fixed Debug View, Improved Scheduler, and Persistent Status.
"""

import sys
import os
import json
import logging
import threading
import time
from pathlib import Path
from datetime import datetime
import tkinter as tk
from tkinter import messagebox, filedialog, scrolledtext

import pystray
from PIL import Image, ImageDraw
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Setup path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from parser.parser_complete import MKParserComplete
except ImportError:
    sys.path.insert(0, str(Path(__file__).parent))
    from parser_complete import MKParserComplete

from security_utils import load_secure_credentials, save_secure_credentials
from uploader import MKUploader

# --- Global Logging Fix ---
log_history = []
class QueueHandler(logging.Handler):
    def emit(self, record):
        try:
            msg = self.format(record)
            log_history.append(msg)
            if len(log_history) > 500: log_history.pop(0)
        except Exception:
            pass

log_queue_handler = QueueHandler()
log_dir = Path(sys.executable).parent / "logs" if getattr(sys, 'frozen', False) else Path(__file__).parent / "logs"
log_dir.mkdir(exist_ok=True)

# Important: Setup logging BEFORE anything else
root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s [%(levelname)s] %(message)s')

fh = logging.FileHandler(log_dir / "agent.log", encoding='utf-8')
fh.setFormatter(formatter)
root_logger.addHandler(fh)

sh = logging.StreamHandler()
sh.setFormatter(formatter)
root_logger.addHandler(sh)

log_queue_handler.setFormatter(formatter)
root_logger.addHandler(log_queue_handler)

logger = logging.getLogger(__name__)

# --- Configuration ---
class Config:
    def __init__(self):
        if getattr(sys, 'frozen', False):
            self.base_dir = Path(sys.executable).parent
        else:
            self.base_dir = Path(__file__).parent
        self.path = self.base_dir / "config.json"
        self.data = {
            "brand_name": "MK Restaurants",
            "branch_code": "MK001",
            "watch_folder": str(self.base_dir / "source"),
            "sync_times": ["12:00", "15:00", "18:00", "23:30"],
            "auto_upload": True,
            "processed_log": str(self.base_dir / "processed_files.json")
        }
        # Load encrypted credentials from credentials.enc
        self.supabase_url, self.supabase_key = load_secure_credentials()
        self.load()

    def load(self):
        if self.path.exists():
            try:
                with open(self.path, 'r', encoding='utf-8') as f:
                    existing = json.load(f)
                    # Update config without credentials
                    clean_existing = {k: v for k, v in existing.items() if k not in ['supabase_url', 'supabase_key']}
                    self.data.update(clean_existing)
            except Exception as e:
                logger.error(f"Error loading config: {e}")

        # Log credential status (not the actual values for security)
        if self.supabase_url and self.supabase_key:
            logger.info(f"Supabase credentials loaded: {self.supabase_url[:20]}...")
        else:
            logger.warning("No Supabase credentials found - upload will fail")

    def save(self):
        try:
            with open(self.path, 'w', encoding='utf-8') as f:
                json.dump(self.data, f, indent=2)
            logger.info("Config saved to disk.")
        except Exception as e:
            logger.error(f"Error saving config: {e}")

# --- Agent Logic ---
class FileHandler(FileSystemEventHandler):
    def __init__(self, agent): self.agent = agent
    def on_created(self, event):
        # Support both Excel (.xls, .xlsx) and PDF (.pdf) files
        if not event.is_directory and event.src_path.lower().endswith(('.xls', '.xlsx', '.pdf')):
            logger.info(f"Detected new file: {Path(event.src_path).name}")
            threading.Timer(2.0, self.agent.process_file, args=[event.src_path]).start()

class MKAgent:
    def __init__(self):
        self.config = Config()
        self.parser = MKParserComplete(self.config.data['branch_code'], self.config.supabase_url, self.config.supabase_key)
        self.uploader = MKUploader(self.config.supabase_url, self.config.supabase_key)
        self.branch_uuid = None
        self.running = True
        self.paused = False
        self.icon = None
        self.status_msg = "Initializing..."
        self.processed_files = self._load_processed_log()
        self.next_sync_time = None  # Track next sync time for debug view
        
        # Ensure folders
        Path(self.config.data['watch_folder']).mkdir(parents=True, exist_ok=True)
        (self.config.base_dir / "processed").mkdir(exist_ok=True)
        logger.info("MK Agent Initialized.")

    def _load_processed_log(self):
        path = Path(self.config.data['processed_log'])
        if path.exists():
            try:
                with open(path, 'r') as f: return set(json.load(f))
            except: pass
        return set()

    def _save_processed_log(self):
        try:
            with open(self.config.data['processed_log'], 'w') as f:
                json.dump(list(self.processed_files), f)
        except Exception as e: logger.error(f"Log save error: {e}")

    def process_file(self, file_path):
        if self.paused or not self.running: return
        file_name = Path(file_path).name
        
        # Deduplication check
        if file_name in self.processed_files:
            logger.info(f"File {file_name} already processed. Skipping.")
            return

        try:
            if not self.branch_uuid:
                logger.info(f"Connecting to fetch Branch UUID for {self.config.data['branch_code']} (Brand: {self.config.data.get('brand_name', 'MK Restaurants')})...")
                self.branch_uuid = self.uploader.get_branch_id(
                    self.config.data['branch_code'], 
                    self.config.data.get('brand_name')
                )
                if not self.branch_uuid:
                    logger.error("Branch ID not found or brand mismatch. Fix config and restart.")
                    return
            
            logger.info(f"Syncing: {file_name}")
            result = self.parser.parse_file(file_path)
            if result.get('success'):
                if self.uploader.upload_result(self.branch_uuid, result):
                    self.processed_files.add(file_name)
                    self._save_processed_log()
                    dest = self.config.base_dir / "processed" / file_name
                    if dest.exists(): 
                        dest = self.config.base_dir / "processed" / f"{datetime.now().strftime('%H%M%S')}_{file_name}"
                    # Move file
                    try:
                        Path(file_path).rename(dest)
                        logger.info(f"Successfully processed and moved: {file_name}")
                    except Exception as e:
                        logger.error(f"Could not move file to processed folder: {e}")
                else:
                    logger.error(f"Database upload failed for: {file_name}")
            else:
                logger.error(f"Parsing error for {file_name}: {result.get('error')}")
        except Exception as e: logger.error(f"Process error: {e}")

    def scheduler_loop(self):
        logger.info("Scheduler thread started.")
        last_trigger = ""
        while self.running:
            if not self.paused:
                now = datetime.now()
                t_str = now.strftime("%H:%M")
                d_str = now.strftime("%Y%m%d")

                # Calculate next sync for status
                sync_times = sorted(self.config.data['sync_times'])
                next_sync = "No times set"
                next_sync_dt = None
                
                if sync_times:
                    found = False
                    for st in sync_times:
                        if st > t_str:
                            next_sync = st
                            # Create datetime for next sync today
                            next_sync_dt = datetime.strptime(f"{d_str} {st}", "%Y%m%d %H:%M")
                            found = True
                            break
                    if not found:
                        # Next sync is tomorrow
                        next_sync = sync_times[0]
                        from datetime import timedelta
                        tomorrow = (now + timedelta(days=1)).strftime("%Y%m%d")
                        next_sync_dt = datetime.strptime(f"{tomorrow} {next_sync}", "%Y%m%d %H:%M")
                
                self.next_sync_time = next_sync_dt
                self.status_msg = f"Status: Idle (Next sync: {next_sync})"

                if t_str in self.config.data['sync_times'] and last_trigger != (d_str + t_str):
                    logger.info(f"Scheduled sync triggered for {t_str}")
                    self.status_msg = f"Status: Syncing scheduled data ({t_str})..."
                    self.manual_sync()
                    last_trigger = d_str + t_str
                    # After sync completes, update status
                    self.status_msg = f"Status: Idle - Last sync completed at {now.strftime('%H:%M:%S')} (Next sync: {next_sync})"
            else:
                self.status_msg = "Status: PAUSED"
            time.sleep(20)

    def manual_sync(self):
        logger.info("Starting sync of all files in watch folder...")
        start_time = datetime.now()
        found_any = False
        watch_path = Path(self.config.data['watch_folder'])
        if not watch_path.exists():
            logger.error(f"Watch folder does not exist: {watch_path}")
            return

        # Materialize list to avoid issues when moving files during iteration
        files = list(watch_path.glob("*.xls*"))
        for f in files:
            found_any = True
            self.process_file(str(f))

        if not found_any:
            logger.info("No files found in watch folder.")
        
        # Update status after completion
        elapsed = (datetime.now() - start_time).total_seconds()
        self.status_msg = f"Status: Idle - Sync completed in {elapsed:.1f}s"
        logger.info(f"Sync completed in {elapsed:.1f} seconds")

    def run_tray(self):
        image = Image.new('RGB', (64, 64), (229, 57, 53))
        draw = ImageDraw.Draw(image)
        draw.rectangle([0, 0, 64, 64], fill=(229, 57, 53))
        draw.text((15, 18), "MK", fill=(255, 255, 255))
        
        menu = pystray.Menu(
            pystray.MenuItem("About", lambda: self.gui_call(self.show_about)),
            pystray.MenuItem("Debug View", lambda: self.gui_call(self.show_debug)),
            pystray.MenuItem("Configure", lambda: self.gui_call(self.show_config)),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem(lambda item: "Resume" if self.paused else "Pause", self.toggle_pause),
            pystray.MenuItem("Sync Now", lambda: threading.Thread(target=self.manual_sync, daemon=True).start()),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Quit", self.quit_app)
        )
        self.icon = pystray.Icon("MKAgent", image, "MK Sales Agent", menu)
        
        threading.Thread(target=self.scheduler_loop, daemon=True).start()
        
        # Start Watchdog
        observer = Observer()
        observer.schedule(FileHandler(self), self.config.data['watch_folder'], recursive=False)
        observer.start()
        
        logger.info("Tray application running.")
        self.icon.run()
        
        observer.stop()
        observer.join()

    def toggle_pause(self, icon, item):
        self.paused = not self.paused
        logger.info(f"Agent state changed: {'PAUSED' if self.paused else 'RUNNING'}")

    def quit_app(self, icon, item):
        logger.info("Agent shutting down.")
        self.running = False
        self.icon.stop()
        os._exit(0)

    # --- GUI Dispatcher ---
    def gui_call(self, func):
        threading.Thread(target=func, daemon=True).start()

    def show_about(self):
        root = tk.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        messagebox.showinfo("About", "MK Agent v2.3\n\nDeveloper: Dr. Bounthong Vongxaya\nMobile/WA: 020 9131 6541")
        root.destroy()

    def show_debug(self):
        win = tk.Tk()
        win.title("MK Agent - Debug View")
        win.geometry("700x500")

        # Status Label with detailed info
        status_frame = tk.Frame(win, bg="white", relief="raised", borderwidth=1)
        status_frame.pack(fill="x", padx=10, pady=5)
        
        status_lbl = tk.Label(status_frame, text=self.status_msg, font=("Arial", 10, "bold"), fg="blue", bg="white", anchor="w", padx=10, pady=5)
        status_lbl.pack(fill="x")
        
        # Next sync info label
        next_sync_lbl = tk.Label(status_frame, text="", font=("Arial", 9), fg="gray", bg="white", anchor="w", padx=10)
        next_sync_lbl.pack(fill="x", pady=(0, 5))

        txt = scrolledtext.ScrolledText(win, font=("Consolas", 9), bg="#f5f5f5")
        txt.pack(expand=1, fill='both', padx=10, pady=5)

        def save_logs():
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            default_filename = f"mk_agent_log_{timestamp}.txt"
            
            file_path = filedialog.asksaveasfilename(
                defaultextension=".txt",
                filetypes=[("Text files", "*.txt"), ("All files", "*.*")],
                initialfile=default_filename,
                title="Save Log File"
            )
            
            if file_path:
                try:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write("\n".join(log_history))
                    logger.info(f"Log saved to: {file_path}")
                    messagebox.showinfo("Success", f"Log saved to:\n{file_path}")
                except Exception as e:
                    logger.error(f"Failed to save log: {e}")
                    messagebox.showerror("Error", f"Failed to save log:\n{str(e)}")

        def copy_logs():
            try:
                win.clipboard_clear()
                win.clipboard_append("\n".join(log_history))
                logger.info("Log copied to clipboard.")
                messagebox.showinfo("Success", "Log copied to clipboard!")
            except Exception as e:
                logger.error(f"Failed to copy log: {e}")
                messagebox.showerror("Error", f"Failed to copy log:\n{str(e)}")

        def clear_logs():
            if messagebox.askyesno("Confirm", "Clear all logs from view?"):
                log_history.clear()
                txt.config(state='normal')
                txt.delete('1.0', tk.END)
                txt.config(state='disabled')
                logger.info("Log view cleared.")

        btn_frame = tk.Frame(win)
        btn_frame.pack(fill="x", side="bottom", pady=10, padx=10)
        
        tk.Button(btn_frame, text="💾 Save Log", command=save_logs, bg="#4CAF50", fg="white", font=("Arial", 9, "bold")).pack(side="left", padx=5)
        tk.Button(btn_frame, text="📋 Copy Log", command=copy_logs, bg="#2196F3", fg="white", font=("Arial", 9, "bold")).pack(side="left", padx=5)
        tk.Button(btn_frame, text="🗑️ Clear Log", command=clear_logs, bg="#f44336", fg="white", font=("Arial", 9, "bold")).pack(side="right", padx=5)

        def refresh():
            if not win.winfo_exists(): return
            
            # Update status with next sync info
            status_lbl.config(text=self.status_msg)
            
            # Calculate and show next sync time
            if hasattr(self, 'next_sync_time') and self.next_sync_time:
                from datetime import datetime
                now = datetime.now()
                time_diff = self.next_sync_time - now
                if time_diff.total_seconds() > 0:
                    hours, remainder = divmod(int(time_diff.total_seconds()), 3600)
                    minutes, seconds = divmod(remainder, 60)
                    next_sync_lbl.config(text=f"Next sync in: {hours:02d}:{minutes:02d}:{seconds:02d} | {self.next_sync_time.strftime('%H:%M:%S')}")
                else:
                    next_sync_lbl.config(text="Next sync: Calculating...")
            else:
                next_sync_lbl.config(text="Status: Running")
            
            # Update log view
            txt.config(state='normal')
            txt.delete('1.0', tk.END)
            txt.insert(tk.END, "\n".join(log_history))
            txt.see(tk.END)
            txt.config(state='disabled')
            win.after(2000, refresh)

        refresh()
        win.mainloop()

    def show_config(self):
        # Force reload from disk to ensure UI is up-to-date
        self.config.load()
        
        # Read fresh values directly from the loaded config file
        try:
            with open(self.config.path, 'r', encoding='utf-8') as f:
                fresh_config = json.load(f)
                branch_code = fresh_config.get('branch_code', 'MK001')
                watch_folder = fresh_config.get('watch_folder', str(self.config.base_dir / "source"))
                sync_times = fresh_config.get('sync_times', ["12:00", "15:00", "18:00", "23:30"])
        except Exception as e:
            logger.error(f"Error reading config file: {e}")
            # Fallback to in-memory data
            branch_code = self.config.data['branch_code']
            watch_folder = self.config.data['watch_folder']
            sync_times = self.config.data['sync_times']

        win = tk.Tk()
        win.title(f"MK Agent - Configuration ({self.config.path.name})")
        win.geometry("450x300")
        win.attributes("-topmost", True)
        
        # Add a label showing the config file path
        config_path_label = tk.Label(win, text=f"File: {self.config.path}", font=("Arial", 8), fg="gray")
        config_path_label.grid(row=0, column=0, columnspan=3, padx=20, pady=5, sticky="w")

        tk.Label(win, text="Brand Name:").grid(row=1, column=0, padx=20, pady=10, sticky="e")
        brand_var = tk.StringVar(value=self.config.data.get('brand_name', 'MK Restaurants'))
        tk.Entry(win, textvariable=brand_var, width=20).grid(row=1, column=1, sticky="w")

        tk.Label(win, text="Branch Code (MKXXX):").grid(row=2, column=0, padx=20, pady=15, sticky="e")
        bc_var = tk.StringVar(value=branch_code)
        tk.Entry(win, textvariable=bc_var, width=20).grid(row=2, column=1, sticky="w")

        tk.Label(win, text="Watch Folder Path:").grid(row=3, column=0, padx=20, pady=10, sticky="e")
        path_var = tk.StringVar(value=watch_folder)
        tk.Entry(win, textvariable=path_var, width=30).grid(row=3, column=1, sticky="w")

        def browse():
            folder = filedialog.askdirectory(initialdir=path_var.get())
            if folder: path_var.set(folder)
        tk.Button(win, text="Browse", command=browse).grid(row=3, column=2, padx=5)

        tk.Label(win, text="Sync Times (HH:MM, ...):").grid(row=4, column=0, padx=20, pady=10, sticky="e")
        times_str = tk.StringVar(value=", ".join(sync_times))
        tk.Entry(win, textvariable=times_str, width=30).grid(row=4, column=1, sticky="w")

        btn_frame = tk.Frame(win)
        btn_frame.grid(row=5, column=1, pady=30, sticky="w")

        def save():
            try:
                raw_times = times_str.get().split(",")
                valid_times = [t.strip() for t in raw_times if ":" in t]

                new_config = {
                    "brand_name": brand_var.get().strip(),
                    "branch_code": bc_var.get().strip(),
                    "watch_folder": path_var.get().strip(),
                    "sync_times": valid_times,
                    "auto_upload": self.config.data.get('auto_upload', True),
                    "processed_log": self.config.data.get('processed_log', str(self.config.base_dir / "processed_files.json"))
                }

                # Save to file
                with open(self.config.path, 'w', encoding='utf-8') as f:
                    json.dump(new_config, f, indent=2)
                
                # Update in-memory data
                self.config.data.update(new_config)
                
                # Update parser branch code
                self.parser.branch_code = new_config['branch_code']
                self.branch_uuid = None  # Force refresh on next upload
                
                logger.info(f"Configuration saved: {new_config}")
                messagebox.showinfo("Success", "Configuration saved.\nPlease restart the agent for changes to take full effect.")
                win.destroy()
            except Exception as e:
                logger.error(f"Save error: {e}")
                messagebox.showerror("Error", f"Failed to save: {e}")

        tk.Button(btn_frame, text="Save Settings", command=save, width=12, bg="#4CAF50", fg="white").pack(side='left', padx=5)
        tk.Button(btn_frame, text="Cancel", command=win.destroy, width=12).pack(side='left', padx=5)
        win.mainloop()

if __name__ == "__main__":
    # Single Instance Lock
    lock_file = Path(os.getenv('TEMP')) / "mk_agent.lock"
    try:
        if lock_file.exists():
            # Check if process is still alive (optional, but good for crashes)
            try:
                os.remove(lock_file)
            except:
                print("Agent already running.")
                sys.exit(0)
        
        with open(lock_file, "w") as f:
            f.write(str(os.getpid()))
            
        import atexit
        def cleanup():
            if lock_file.exists(): os.remove(lock_file)
        atexit.register(cleanup)
        
        MKAgent().run_tray()
    except Exception as e:
        logger.critical(f"Application crashed: {e}")
        sys.exit(1)
