# PROPOSAL: AUTOMATED SALES INTELLIGENCE SYSTEM
## Mobile Executive Dashboard for MK Restaurants Laos

---

**To:** President Viphet Sihachack  
**Cc:** Head of Accounting, Head of IT, General Manager  
**From:** Dr. Bounthong Vongxaya  
**Date:** February 19, 2026  
**Subject:** Updated Proposal & Quotation for Sales Consolidation System

---

## 1. EXECUTIVE SUMMARY

This proposal presents a comprehensive solution to automate sales data consolidation across all MK Restaurant branches in Laos. The system transforms manual reporting into an intelligent, real-time dashboard accessible via mobile devices.

### Key Benefits

| Benefit | Current State | After Implementation |
|---------|---------------|---------------------|
| Data Visibility | Next day (Manual) | **Same day (Instant)** or Next day (Auto) |
| Manual Work | Hours daily | Zero (Staff clicks one button) |
| Decision Speed | Delayed | Instant mobile access |
| Branch Comparison | Manual spreadsheet | Real-time dashboard |
| Alert System | None | Automatic exception alerts |

---

## 2. CURRENT CHALLENGES

### 2.1 Data Latency
- Sales data trapped in individual branch systems until end of day.
- No visibility into performance until next day.
- Cross-branch comparison requires manual consolidation.
- **Management Insight:** Currently, the President only sees yesterday's performance today.

### 2.2 Manual Bottleneck
- Accounting team spends hours daily on data collection and consolidation.
- Human errors in data transcription.
- Delayed financial reporting.

---

## 3. PROPOSED SOLUTION

### 3.1 System Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    AUTOMATED DATA PIPELINE                     │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│   BRANCH 1          BRANCH 2          BRANCH 3                │
│   ┌──────┐          ┌──────┐          ┌──────┐                │
│   │ POS  │          │ POS  │          │ POS  │                │
│   └──┬───┘          └──┬───┘          └──┬───┘                │
│      │                 │                 │                    │
│      ▼                 ▼                 ▼                    │
│   ┌──────┐          ┌──────┐          ┌──────┐                │
│   │ XLS  │          │ XLS  │          │ XLS  │                │
│   │Files │          │Files │          │Files │                │
│   └──┬───┘          └──┬───┘          └──┬───┘                │
│      │                 │                 │                    │
│      ▼                 ▼                 ▼                    │
│   ┌──────────────────────────────────────────────┐            │
│   │           LOCAL AGENT (Tray App)              │            │
│   │  • Auto-detects new files (Midnight Sync)     │            │
│   │  • Manual 'Sync Now' button for staff         │            │
│   │  • Parses & validates data                    │            │
│   │  • Uploads to cloud                           │            │
│   └──────────────────────┬───────────────────────┘            │
│                          │                                    │
└──────────────────────────┼────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                    SUPABASE (Cloud Platform)                    │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐                    │
│   │PostgreSQL│  │  Auth    │  │REST API  │                    │
│   │Database  │  │ Service  │  │(Auto)    │                    │
│   └──────────┘  └──────────┘  └──────────┘                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                      MOBILE DASHBOARD                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│   ┌─────────────────────────────────────────────┐             │
│   │         FLUTTER MOBILE APP                   │             │
│   │  (iOS & Android)                             │             │
│   │                                              │             │
│   │  • Today's Sales Overview                    │             │
│   │  • Branch Comparison                         │             │
│   │  • Peak Hours Analysis                       │             │
│   │  • Product Performance                       │             │
│   │  • Void & Exception Alerts                   │             │
│   │  • Historical Trends                         │             │
│   └─────────────────────────────────────────────┘             │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 3.2 Key Features

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Hybrid Sync Mode** | **Automatic:** Syncs at midnight. **Manual:** Staff clicks 'Sync Now' after export for instant dashboard updates. |
| 2 | **Strategic Visibility** | President can request noon or evening exports for a "Live" overview of lunch and dinner performance. |
| 3 | **Multi-Branch Dashboard** | See all 3 branches in one view |
| 4 | **Sales Trends** | Daily, weekly, monthly comparisons |
| 5 | **Peak Hour Analysis** | Visual charts of busy periods |
| 6 | **Product Performance** | Top sellers and category breakdown |
| 7 | **Exception Alerts** | Void transactions, unusual patterns |
| 8 | **Mobile Access** | Beautiful app on iOS and Android |

---

## 4. IMPLEMENTATION PLAN

The project is structured into three clear deliverables. Payment is tied to the completion of each stage rather than arbitrary dates.

### Deliverable 1: Functional Prototype
- Complete Database & Cloud Setup
- XLS Parser Module (all 17 formats)
- Local Agent (Tray App) with 'Sync Now' feature
- Mobile App Core Screens & Real Data Integration
- **Goal:** President can see actual branch data on his phone.

### Deliverable 2: Refinement & Improvements
- Incorporate feedback from President and Management
- Detailed Charts, Peak Hour Heatmaps, and Trend Analysis
- Void & Exception Alert System
- **Goal:** System is tailored exactly to MK Management requirements.

### Deliverable 3: Full Branch Rollout & Go-Live
- Installation at all 3 MK Branch locations
- Staff training on Excel export & 'Sync Now' process
- Final system testing and 3-month support period
- **Goal:** Entire organization is live and data-driven.

---

## 5. TECHNOLOGY STACK

| Component | Technology | Notes |
|-----------|------------|-------|
| **Cloud Platform** | Supabase | Free tier for development, $25/mo production |
| **Database** | PostgreSQL | Included in Supabase |
| **Authentication** | Supabase Auth | Built-in, no extra work |
| **API** | Auto-generated | Supabase REST API |
| **Local Agent** | Python + PyQt | Windows tray application |
| **Mobile App** | Flutter | iOS & Android |
| **Charts** | FL Chart | Beautiful visualizations |

---

## 6. QUOTATION

### Special Founding Partner Pricing

> **Note:** This quotation reflects a **60% Founding Partner Discount** extended exclusively to MK Restaurants Laos as our pilot launch partner. This pricing reflects our commitment to building a long-term strategic partnership.

---

### Phase 1: Core System

| Component | Standard Price | Pilot Discount | Your Price |
|-----------|---------------|----------------|------------|
| Database & Cloud Setup | $600 | 60% off | $240 |
| XLS Parser Module | $1,125 | 60% off | $450 |
| Local Agent (Tray App) | $1,350 | 60% off | $540 |
| Flutter Mobile App | $2,625 | 60% off | $1,050 |
| Dashboard & Charts | $900 | 60% off | $360 |
| Testing & Deployment | $450 | 60% off | $180 |
| Documentation & Training | $225 | 60% off | $90 |
| **Phase 1 Total** | **$7,275** | **60% off** | **$2,910** |

### Phase 2: AI & WhatsApp (Optional)

| Component | Standard Price | Pilot Discount | Your Price |
|-----------|---------------|----------------|------------|
| WhatsApp Integration | $300 | 60% off | $120 |
| AI Assistant | $900 | 60% off | $360 |
| **Phase 2 Total** | **$1,200** | **60% off** | **$480** |

---

## 7. TOTAL INVESTMENT

| Phase | Amount |
|-------|--------|
| **Phase 1 (Core System)** | $2,910 |
| Phase 2 (Optional) | $480 |
| **Project Total** | **$2,910 - $3,390** |
| Annual Cloud Hosting (after launch) | $300 |

Note: In longterm, Alternatively we can setup our own pc server with appropriate capacity.


---

## 8. PAYMENT SCHEDULE

Payments are tied to the delivery of specific system components.

| Deliverable | Milestone | Amount |
|-----------|--------|--------|
| **Project Start** | Down payment to begin work | $500 |
| **Deliverable 1** | **Functional Prototype** (Actual data on phone) | $1,000 |
| **Deliverable 2** | **Improved App** (Based on your feedback) | $1,000 |
| **Deliverable 3** | **Go Live** (All 3 MK Branch locations) | $410 |
| **Total Phase 1** | | **$2,910** |

---

## 9. WHAT'S INCLUDED

### Software Deliverables
- Windows tray application (installer included)
- Android app (APK + Play Store submission)
- iOS app (App Store submission)
- Cloud database (hosted on Supabase)

### Support
- 3 months free support after launch
- Bug fixes at no cost
- Priority email support

---

## 10. INFRASTRUCTURE COSTS

### Development Period
- **Supabase Free Tier**: $0/month

### Production Period
- **Supabase Pro**: $25/month ($300/year)

---

## 11. SUCCESS METRICS

| Metric | Target |
|--------|--------|
| Dashboard load time | < 3 seconds |
| Data sync time | < 5 minutes after 'Sync Now' click |
| Manual data entry | Zero (Fully Automated) |
| President visibility | **Near real-time** (if staff exports frequently) |

---

## 12. NEXT STEPS

1. **Approve Proposal** - Sign and return.
2. **Initial Payment** - $1,000 to initiate Deliverable 1.
3. **Weekly Progress** - Weekly demo of the prototype development.

---

## 13. ACCEPTANCE

**Client:**  
_____________________________  
President Viphet Sihachack  
MK Restaurants Laos  
Date: _______________

**Provider:**  
_____________________________  
Dr. Bounthong Vongxaya  
Date: _______________

---

*Proposal Version: 2.1*  
*Special Founding Partner Pricing*  
*Contact: 020 9131 6541*
