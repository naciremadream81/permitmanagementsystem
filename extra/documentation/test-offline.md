# Testing Offline-First Functionality

## Test Scenarios

### 1. **Online → Offline Transition**
- Start app with internet connection
- Login and load data
- Disconnect internet
- Create new permit package
- Update package status
- Verify UI shows "offline" status
- Verify changes are saved locally

### 2. **Offline → Online Sync**
- Reconnect internet
- Verify sync status shows "syncing"
- Verify local changes are pushed to server
- Verify sync completes successfully

### 3. **Pure Offline Mode**
- Start app without internet
- Login with cached credentials
- Browse cached counties and checklists
- Create permit packages offline
- Verify all data persists locally

## UI Indicators to Look For

✅ **Status Indicators:**
- 🟢 Online / 🔴 Offline badge
- 🔄 Sync progress indicator
- ⚠️ "Working offline" messages

✅ **Sync Controls:**
- Manual "Sync Now" button
- Last sync timestamp
- Pending operations count

✅ **Offline Feedback:**
- "Package created offline - will sync when online"
- "Status updated offline - will sync when online"
- "Working offline - data may not be current"

## Database Files

The offline database will be created at:
- **Desktop**: `~/tmp/permit_database.db`
- **Android**: App's private database directory
- **iOS**: App's documents directory

## Next Steps for Full Implementation

1. **File Upload Offline**: Store files locally and sync when online
2. **Conflict Resolution**: Handle server conflicts during sync
3. **Data Compression**: Optimize sync payload size
4. **Incremental Sync**: Only sync changed data
5. **User Notifications**: Alert users about sync status changes
