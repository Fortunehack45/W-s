package admin

const DashboardHTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>W's Platform — Super Admin Control Center</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <style>
    body { background-color: #0b0c10; color: #e0e2ec; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    .gold-accent { color: #ffd700; }
    .border-gold { border-color: rgba(255, 215, 0, 0.3); }
    .bg-card { background-color: #161822; }
    .bg-surface { background-color: #1f2233; }
    .badge-gold { background: rgba(255, 215, 0, 0.15); color: #ffd700; border: 1px solid rgba(255, 215, 0, 0.4); }
    .badge-cyan { background: rgba(0, 229, 255, 0.15); color: #00e5ff; border: 1px solid rgba(0, 229, 255, 0.4); }
    .badge-red { background: rgba(255, 61, 0, 0.15); color: #ff3d00; border: 1px solid rgba(255, 61, 0, 0.4); }
  </style>
</head>
<body class="min-h-screen flex">
  <!-- Sidebar -->
  <aside class="w-64 bg-card border-r border-gray-800 flex flex-col justify-between">
    <div>
      <div class="p-6 border-b border-gray-800 flex items-center space-x-3">
        <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-amber-500 to-yellow-300 flex items-center justify-center shadow-lg shadow-amber-500/20">
          <i class="fa-solid fa-bolt text-black text-xl font-black"></i>
        </div>
        <div>
          <h1 class="text-lg font-black tracking-wide text-white">W's Admin</h1>
          <p class="text-xs text-amber-400 font-medium">SUPER CONTROL PANEL</p>
        </div>
      </div>
      <nav class="p-4 space-y-1">
        <button onclick="switchTab('overview')" id="nav-overview" class="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold bg-amber-500/10 text-amber-400">
          <i class="fa-solid fa-chart-pie w-5"></i><span>Overview</span>
        </button>
        <button onclick="switchTab('users')" id="nav-users" class="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold text-gray-400 hover:text-white hover:bg-surface">
          <i class="fa-solid fa-users w-5"></i><span>User Accounts</span>
        </button>
        <button onclick="switchTab('activities')" id="nav-activities" class="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold text-gray-400 hover:text-white hover:bg-surface">
          <i class="fa-solid fa-clock-rotate-left w-5"></i><span>Live Activities</span>
        </button>
        <button onclick="switchTab('comments')" id="nav-comments" class="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold text-gray-400 hover:text-white hover:bg-surface">
          <i class="fa-solid fa-comments w-5"></i><span>Post Comments</span>
        </button>
        <button onclick="switchTab('chats')" id="nav-chats" class="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold text-gray-400 hover:text-white hover:bg-surface">
          <i class="fa-solid fa-video w-5"></i><span>Video Chats</span>
        </button>
        <button onclick="switchTab('dms')" id="nav-dms" class="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold text-gray-400 hover:text-white hover:bg-surface">
          <i class="fa-solid fa-paper-plane w-5"></i><span>DMs & Messages</span>
        </button>
        <button onclick="switchTab('appeals')" id="nav-appeals" class="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold text-gray-400 hover:text-white hover:bg-surface">
          <i class="fa-solid fa-shield-halved w-5"></i><span>Bot Appeals</span>
        </button>
      </nav>
    </div>
    <div class="p-4 border-t border-gray-800">
      <div class="flex items-center justify-between text-xs text-gray-500">
        <span>Engine v2.4</span>
        <span class="flex items-center text-emerald-400"><span class="w-2 h-2 rounded-full bg-emerald-400 mr-1.5 animate-pulse"></span>Connected</span>
      </div>
    </div>
  </aside>

  <!-- Main Content Area -->
  <main class="flex-1 flex flex-col overflow-y-auto">
    <!-- Top Header -->
    <header class="h-16 bg-card/60 backdrop-blur border-b border-gray-800 px-8 flex items-center justify-between sticky top-0 z-10">
      <div class="flex items-center space-x-3">
        <span id="tab-title" class="text-xl font-bold text-white">Platform Health & Overview</span>
      </div>
      <div class="flex items-center space-x-4">
        <button onclick="refreshAll()" class="px-3 py-1.5 bg-surface hover:bg-gray-700 text-xs font-semibold rounded-lg text-gray-200 flex items-center space-x-2">
          <i class="fa-solid fa-arrows-rotate"></i><span>Refresh Data</span>
        </button>
        <span class="px-2.5 py-1 text-xs rounded-full bg-emerald-500/20 text-emerald-400 font-medium">Production Admin</span>
      </div>
    </header>

    <div class="p-8 space-y-8">
      <!-- 1. OVERVIEW TAB -->
      <section id="view-overview" class="space-y-6">
        <!-- KPI Cards Grid -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="bg-card p-5 rounded-2xl border border-gray-800">
            <div class="flex justify-between items-start">
              <span class="text-xs uppercase text-gray-400 font-semibold tracking-wider">Total Users</span>
              <i class="fa-solid fa-users text-amber-400"></i>
            </div>
            <div class="mt-3 text-3xl font-black text-white" id="stat-total-users">-</div>
            <div class="mt-1 text-xs text-gray-400"><span id="stat-verified-users" class="text-amber-400 font-bold">0</span> Verified Creators</div>
          </div>

          <div class="bg-card p-5 rounded-2xl border border-gray-800">
            <div class="flex justify-between items-start">
              <span class="text-xs uppercase text-gray-400 font-semibold tracking-wider">Restricted Bots</span>
              <i class="fa-solid fa-robot text-red-400"></i>
            </div>
            <div class="mt-3 text-3xl font-black text-red-400" id="stat-restricted-users">-</div>
            <div class="mt-1 text-xs text-gray-400">Passive preview mode enforced</div>
          </div>

          <div class="bg-card p-5 rounded-2xl border border-gray-800">
            <div class="flex justify-between items-start">
              <span class="text-xs uppercase text-gray-400 font-semibold tracking-wider">Videos Published</span>
              <i class="fa-solid fa-film text-cyan-400"></i>
            </div>
            <div class="mt-3 text-3xl font-black text-white" id="stat-total-videos">-</div>
            <div class="mt-1 text-xs text-gray-400"><span id="stat-total-views" class="text-cyan-400 font-bold">0</span> Total Views</div>
          </div>

          <div class="bg-card p-5 rounded-2xl border border-gray-800">
            <div class="flex justify-between items-start">
              <span class="text-xs uppercase text-gray-400 font-semibold tracking-wider">Active Streaks</span>
              <i class="fa-solid fa-fire text-amber-500"></i>
            </div>
            <div class="mt-3 text-3xl font-black text-amber-400" id="stat-active-streaks">-</div>
            <div class="mt-1 text-xs text-gray-400">Daily DM streak pairs</div>
          </div>
        </div>

        <!-- Recent Real-time Audit Stream -->
        <div class="bg-card rounded-2xl border border-gray-800 p-6">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-base font-bold text-white flex items-center space-x-2">
              <i class="fa-solid fa-bolt text-amber-400"></i><span>Real-Time Platform Event Stream</span>
            </h3>
            <span class="text-xs text-gray-400">Auto-logged</span>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left text-sm text-gray-300">
              <thead class="text-xs uppercase text-gray-500 bg-surface">
                <tr>
                  <th class="px-4 py-3 rounded-l-lg">Time</th>
                  <th class="px-4 py-3">Event Type</th>
                  <th class="px-4 py-3">Actor</th>
                  <th class="px-4 py-3 rounded-r-lg">Details</th>
                </tr>
              </thead>
              <tbody id="overview-activities-body" class="divide-y divide-gray-800/50">
                <tr><td colspan="4" class="px-4 py-6 text-center text-gray-500">Loading events...</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- 2. USERS TAB -->
      <section id="view-users" class="space-y-4 hidden">
        <div class="flex justify-between items-center">
          <div class="relative w-80">
            <i class="fa-solid fa-magnifying-glass absolute left-3 top-3 text-gray-500 text-sm"></i>
            <input type="text" id="user-search" oninput="loadUsers()" placeholder="Search username, ID..." class="w-full pl-9 pr-4 py-2 bg-card border border-gray-800 rounded-lg text-sm text-white placeholder-gray-500 focus:outline-none focus:border-amber-400">
          </div>
          <div class="flex space-x-2">
            <select id="user-filter" onchange="loadUsers()" class="bg-card border border-gray-800 rounded-lg text-sm text-gray-300 px-3 py-2">
              <option value="all">All Users</option>
              <option value="normal">Normal Users</option>
              <option value="restricted">Restricted (Bots)</option>
            </select>
          </div>
        </div>

        <div class="bg-card rounded-2xl border border-gray-800 overflow-hidden">
          <table class="w-full text-left text-sm text-gray-300">
            <thead class="text-xs uppercase text-gray-500 bg-surface">
              <tr>
                <th class="px-5 py-3">User</th>
                <th class="px-5 py-3">Status</th>
                <th class="px-5 py-3">Followers</th>
                <th class="px-5 py-3">Total Earned W</th>
                <th class="px-5 py-3">Videos</th>
                <th class="px-5 py-3 text-right">Moderation Actions</th>
              </tr>
            </thead>
            <tbody id="users-table-body" class="divide-y divide-gray-800">
              <tr><td colspan="6" class="px-5 py-8 text-center text-gray-500">Loading users...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 3. LIVE ACTIVITIES TAB -->
      <section id="view-activities" class="space-y-4 hidden">
        <div class="bg-card rounded-2xl border border-gray-800 overflow-hidden p-6">
          <h3 class="text-lg font-bold text-white mb-4">Complete Audit Trail</h3>
          <table class="w-full text-left text-sm text-gray-300">
            <thead class="text-xs uppercase text-gray-500 bg-surface">
              <tr>
                <th class="px-5 py-3">Timestamp</th>
                <th class="px-5 py-3">Type</th>
                <th class="px-5 py-3">User ID</th>
                <th class="px-5 py-3">Username</th>
                <th class="px-5 py-3">Activity Description</th>
              </tr>
            </thead>
            <tbody id="full-activities-body" class="divide-y divide-gray-800">
              <tr><td colspan="5" class="px-5 py-8 text-center text-gray-500">Loading activity trail...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 4. COMMENTS TAB -->
      <section id="view-comments" class="space-y-4 hidden">
        <div class="bg-card rounded-2xl border border-gray-800 overflow-hidden p-6">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-bold text-white">Post Comments Stream</h3>
            <span class="text-xs text-gray-400">Anti-bot velocity monitoring active</span>
          </div>
          <table class="w-full text-left text-sm text-gray-300">
            <thead class="text-xs uppercase text-gray-500 bg-surface">
              <tr>
                <th class="px-5 py-3">Author</th>
                <th class="px-5 py-3">Video ID</th>
                <th class="px-5 py-3">Comment Text</th>
                <th class="px-5 py-3">Daily Velocity</th>
                <th class="px-5 py-3">Bot Flag</th>
                <th class="px-5 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody id="comments-table-body" class="divide-y divide-gray-800">
              <tr><td colspan="6" class="px-5 py-8 text-center text-gray-500">Loading comments...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 5. VIDEO CHATS TAB -->
      <section id="view-chats" class="space-y-4 hidden">
        <div class="bg-card rounded-2xl border border-gray-800 overflow-hidden p-6">
          <h3 class="text-lg font-bold text-white mb-4">Canonical Video Chat Messages</h3>
          <table class="w-full text-left text-sm text-gray-300">
            <thead class="text-xs uppercase text-gray-500 bg-surface">
              <tr>
                <th class="px-5 py-3">Timestamp</th>
                <th class="px-5 py-3">Video ID</th>
                <th class="px-5 py-3">Author</th>
                <th class="px-5 py-3">Backer Badge</th>
                <th class="px-5 py-3">Message</th>
              </tr>
            </thead>
            <tbody id="chats-table-body" class="divide-y divide-gray-800">
              <tr><td colspan="5" class="px-5 py-8 text-center text-gray-500">Loading video chats...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 6. DMs TAB -->
      <section id="view-dms" class="space-y-4 hidden">
        <div class="bg-card rounded-2xl border border-gray-800 overflow-hidden p-6">
          <h3 class="text-lg font-bold text-white mb-4">Direct Messages (DMs / DNS) Audit Inspector</h3>
          <table class="w-full text-left text-sm text-gray-300">
            <thead class="text-xs uppercase text-gray-500 bg-surface">
              <tr>
                <th class="px-5 py-3">Timestamp</th>
                <th class="px-5 py-3">Thread ID</th>
                <th class="px-5 py-3">Sender</th>
                <th class="px-5 py-3">Message Content</th>
                <th class="px-5 py-3">Read Status</th>
              </tr>
            </thead>
            <tbody id="dms-table-body" class="divide-y divide-gray-800">
              <tr><td colspan="5" class="px-5 py-8 text-center text-gray-500">Loading direct messages...</td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 7. APPEALS TAB -->
      <section id="view-appeals" class="space-y-4 hidden">
        <div class="bg-card rounded-2xl border border-gray-800 overflow-hidden p-6">
          <h3 class="text-lg font-bold text-white mb-4">Bot Restriction Appeals Queue</h3>
          <table class="w-full text-left text-sm text-gray-300">
            <thead class="text-xs uppercase text-gray-500 bg-surface">
              <tr>
                <th class="px-5 py-3">Date</th>
                <th class="px-5 py-3">User ID</th>
                <th class="px-5 py-3">Reason</th>
                <th class="px-5 py-3">User Appeal Message</th>
                <th class="px-5 py-3">Status</th>
                <th class="px-5 py-3 text-right">Decision</th>
              </tr>
            </thead>
            <tbody id="appeals-table-body" class="divide-y divide-gray-800">
              <tr><td colspan="6" class="px-5 py-8 text-center text-gray-500">No pending appeals found.</td></tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  </main>

  <script>
    var activeTab = 'overview';

    function switchTab(tab) {
      document.querySelectorAll('main section').forEach(function(el) { el.classList.add('hidden'); });
      document.querySelectorAll('aside nav button').forEach(function(el) {
        el.className = 'w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold text-gray-400 hover:text-white hover:bg-surface';
      });

      document.getElementById('view-' + tab).classList.remove('hidden');
      var navBtn = document.getElementById('nav-' + tab);
      if (navBtn) {
        navBtn.className = 'w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-semibold bg-amber-500/10 text-amber-400';
      }

      var titles = {
        overview: 'Platform Health & Overview',
        users: 'User Account Registry & Moderation',
        activities: 'Live Platform Audit Trail',
        comments: 'Post Comments & Spam Monitor',
        chats: 'Canonical Video Chat Rooms',
        dms: 'Direct Messaging (DMs / DNS) Audit',
        appeals: 'Bot Restriction Appeals Queue'
      };
      document.getElementById('tab-title').textContent = titles[tab] || 'W\'s Admin';
      activeTab = tab;

      if (tab === 'overview') loadOverview();
      if (tab === 'users') loadUsers();
      if (tab === 'activities') loadActivities();
      if (tab === 'comments') loadComments();
      if (tab === 'chats') loadChats();
      if (tab === 'dms') loadDMs();
      if (tab === 'appeals') loadAppeals();
    }

    async function loadOverview() {
      try {
        var statsRes = await fetch('/api/v1/admin/stats');
        var stats = await statsRes.json();
        document.getElementById('stat-total-users').textContent = stats.totalUsers || 0;
        document.getElementById('stat-verified-users').textContent = stats.verifiedUsers || 0;
        document.getElementById('stat-restricted-users').textContent = stats.restrictedUsers || 0;
        document.getElementById('stat-total-videos').textContent = stats.totalVideos || 0;
        document.getElementById('stat-total-views').textContent = (stats.totalVideoViews || 0).toLocaleString();
        document.getElementById('stat-active-streaks').textContent = stats.activeStreaks || 0;

        var actRes = await fetch('/api/v1/admin/activities?limit=10');
        var acts = await actRes.json();
        var tbody = document.getElementById('overview-activities-body');
        if (!acts || acts.length === 0) {
          tbody.innerHTML = '<tr><td colspan="4" class="px-4 py-6 text-center text-gray-500">No events yet.</td></tr>';
          return;
        }
        var html = '';
        for (var i = 0; i < acts.length; i++) {
          var a = acts[i];
          html += '<tr>' +
            '<td class="px-4 py-3 text-xs text-gray-400 font-mono">' + new Date(a.timestamp).toLocaleTimeString() + '</td>' +
            '<td class="px-4 py-3"><span class="px-2 py-0.5 text-xs rounded font-medium bg-gray-800 text-amber-400">' + a.type + '</span></td>' +
            '<td class="px-4 py-3 font-semibold text-white">@' + a.username + '</td>' +
            '<td class="px-4 py-3 text-gray-300">' + a.details + '</td>' +
          '</tr>';
        }
        tbody.innerHTML = html;
      } catch (err) {
        console.error(err);
      }
    }

    async function loadUsers() {
      var q = document.getElementById('user-search').value;
      var f = document.getElementById('user-filter').value;
      var url = '/api/v1/admin/users?query=' + encodeURIComponent(q);
      if (f === 'restricted') url += '&restricted=true';
      if (f === 'normal') url += '&restricted=false';

      var res = await fetch(url);
      var users = await res.json();
      var tbody = document.getElementById('users-table-body');
      if (!users || users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="px-5 py-8 text-center text-gray-500">No users found.</td></tr>';
        return;
      }
      var html = '';
      for (var i = 0; i < users.length; i++) {
        var u = users[i];
        var isRestr = u.restrictionStatus === 'restricted';
        var statusBadge = isRestr 
          ? '<span class="px-2.5 py-1 text-xs rounded-full badge-red font-semibold">RESTRICTED (BOT)</span>' 
          : '<span class="px-2.5 py-1 text-xs rounded-full bg-emerald-500/10 text-emerald-400 font-semibold">NORMAL</span>';
        var verifiedBadge = u.isVerified ? '<i class="fa-solid fa-circle-check text-amber-400 text-xs ml-1.5" title="Verified Creator"></i>' : '';
        var premiumBadge = u.isPremium ? '<span class="ml-1.5 px-1.5 py-0.5 text-[10px] rounded bg-purple-500/20 text-purple-300 font-bold">PREMIUM</span>' : '';
        var initial = (u.username || 'U')[0].toUpperCase();

        var restrAction = isRestr
          ? '<button onclick="toggleRestriction(\'' + u.id + '\', false)" class="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 text-xs font-semibold rounded text-white">Unrestrict</button>'
          : '<button onclick="toggleRestriction(\'' + u.id + '\', true)" class="px-3 py-1 bg-red-600/80 hover:bg-red-600 text-xs font-semibold rounded text-white">Restrict Bot</button>';

        var verifyAction = u.isVerified
          ? '<button onclick="toggleVerify(\'' + u.id + '\', false)" class="px-3 py-1 bg-gray-700 hover:bg-gray-600 text-xs font-semibold rounded text-gray-300">Unverify</button>'
          : '<button onclick="toggleVerify(\'' + u.id + '\', true)" class="px-3 py-1 bg-amber-500 hover:bg-amber-400 text-xs font-semibold rounded text-black font-bold">Verify</button>';

        html += '<tr>' +
          '<td class="px-5 py-4"><div class="flex items-center space-x-3">' +
            '<div class="w-9 h-9 rounded-full bg-gray-700 flex items-center justify-center font-bold text-amber-400">' + initial + '</div>' +
            '<div><div class="font-bold text-white flex items-center">@' + u.username + verifiedBadge + premiumBadge + '</div>' +
            '<div class="text-xs text-gray-500 font-mono">' + u.id.substring(0, 8) + '...</div></div></div></td>' +
          '<td class="px-5 py-4">' + statusBadge + '</td>' +
          '<td class="px-5 py-4 font-semibold text-white">' + u.followersCount + '</td>' +
          '<td class="px-5 py-4 font-black text-amber-400">' + (u.totalEarnedW || 0).toLocaleString() + ' W</td>' +
          '<td class="px-5 py-4 text-gray-300">' + u.videoCount + '</td>' +
          '<td class="px-5 py-4 text-right space-x-2">' + restrAction + verifyAction + '</td>' +
        '</tr>';
      }
      tbody.innerHTML = html;
    }

    async function toggleRestriction(userId, restrict) {
      await fetch('/api/v1/admin/users/' + userId + '/restrict?restrict=' + restrict, { method: 'POST' });
      loadUsers();
      loadOverview();
    }

    async function toggleVerify(userId, verify) {
      await fetch('/api/v1/admin/users/' + userId + '/verify?verify=' + verify, { method: 'POST' });
      loadUsers();
      loadOverview();
    }

    async function loadActivities() {
      var res = await fetch('/api/v1/admin/activities?limit=100');
      var acts = await res.json();
      var tbody = document.getElementById('full-activities-body');
      if (!acts || acts.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="px-5 py-8 text-center text-gray-500">No events found.</td></tr>';
        return;
      }
      var html = '';
      for (var i = 0; i < acts.length; i++) {
        var a = acts[i];
        html += '<tr>' +
          '<td class="px-5 py-3 text-xs text-gray-400 font-mono">' + new Date(a.timestamp).toLocaleString() + '</td>' +
          '<td class="px-5 py-3"><span class="px-2 py-0.5 text-xs rounded bg-gray-800 text-amber-400 font-medium">' + a.type + '</span></td>' +
          '<td class="px-5 py-3 font-mono text-xs text-gray-500">' + a.userId + '</td>' +
          '<td class="px-5 py-3 font-bold text-white">@' + a.username + '</td>' +
          '<td class="px-5 py-3 text-gray-300">' + a.details + '</td>' +
        '</tr>';
      }
      tbody.innerHTML = html;
    }

    async function loadComments() {
      var res = await fetch('/api/v1/admin/comments?limit=50');
      var comments = await res.json();
      var tbody = document.getElementById('comments-table-body');
      if (!comments || comments.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="px-5 py-8 text-center text-gray-500">No comments posted yet.</td></tr>';
        return;
      }
      var html = '';
      for (var i = 0; i < comments.length; i++) {
        var c = comments[i];
        var flag = c.isFlagged
          ? '<span class="px-2 py-0.5 text-xs rounded bg-red-500/20 text-red-400 font-bold">SPAM BOT FLAG</span>'
          : '<span class="px-2 py-0.5 text-xs rounded bg-gray-800 text-gray-400">Normal</span>';
        var velColor = c.spamVelocity >= 100 ? 'text-red-400 font-bold' : 'text-gray-400';

        html += '<tr>' +
          '<td class="px-5 py-3 font-semibold text-white">@' + c.authorUsername + '</td>' +
          '<td class="px-5 py-3 font-mono text-xs text-gray-500">' + c.videoId.substring(0, 8) + '...</td>' +
          '<td class="px-5 py-3 text-gray-200">' + c.content + '</td>' +
          '<td class="px-5 py-3 font-mono ' + velColor + '">' + c.spamVelocity + ' / day</td>' +
          '<td class="px-5 py-3">' + flag + '</td>' +
          '<td class="px-5 py-3 text-right space-x-2">' +
            '<button onclick="deleteComment(\'' + c.id + '\')" class="px-2.5 py-1 bg-red-600/80 hover:bg-red-600 text-xs font-semibold rounded text-white">Delete</button>' +
            '<button onclick="toggleRestriction(\'' + c.authorId + '\', true)" class="px-2.5 py-1 bg-gray-700 hover:bg-gray-600 text-xs font-semibold rounded text-gray-200">Restrict Author</button>' +
          '</td>' +
        '</tr>';
      }
      tbody.innerHTML = html;
    }

    async function deleteComment(id) {
      await fetch('/api/v1/admin/comments/' + id, { method: 'DELETE' });
      loadComments();
    }

    async function loadChats() {
      var res = await fetch('/api/v1/admin/chats?limit=50');
      var msgs = await res.json();
      var tbody = document.getElementById('chats-table-body');
      if (!msgs || msgs.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="px-5 py-8 text-center text-gray-500">No canonical video chat messages recorded yet.</td></tr>';
        return;
      }
      var html = '';
      for (var i = 0; i < msgs.length; i++) {
        var m = msgs[i];
        var badge = m.topBackerBadge 
          ? '<span class="px-2 py-0.5 text-xs rounded badge-gold font-bold">' + m.topBackerBadge + '</span>'
          : '<span class="text-xs text-gray-500">-</span>';

        html += '<tr>' +
          '<td class="px-5 py-3 text-xs text-gray-400 font-mono">' + new Date(m.createdAt).toLocaleTimeString() + '</td>' +
          '<td class="px-5 py-3 font-mono text-xs text-gray-500">' + m.videoId.substring(0, 8) + '...</td>' +
          '<td class="px-5 py-3 font-semibold text-white">@' + m.username + '</td>' +
          '<td class="px-5 py-3">' + badge + '</td>' +
          '<td class="px-5 py-3 text-gray-200">' + m.content + '</td>' +
        '</tr>';
      }
      tbody.innerHTML = html;
    }

    async function loadDMs() {
      var res = await fetch('/api/v1/admin/dms?limit=50');
      var dms = await res.json();
      var tbody = document.getElementById('dms-table-body');
      if (!dms || dms.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="px-5 py-8 text-center text-gray-500">No 1-on-1 direct messages sent yet.</td></tr>';
        return;
      }
      var html = '';
      for (var i = 0; i < dms.length; i++) {
        var d = dms[i];
        var readStatus = d.isRead ? '<span class="text-xs text-emerald-400">Read</span>' : '<span class="text-xs text-gray-500">Unread</span>';

        html += '<tr>' +
          '<td class="px-5 py-3 text-xs text-gray-400 font-mono">' + new Date(d.createdAt).toLocaleTimeString() + '</td>' +
          '<td class="px-5 py-3 font-mono text-xs text-gray-500">' + d.threadId.substring(0, 8) + '...</td>' +
          '<td class="px-5 py-3 font-semibold text-amber-400">@' + d.senderUsername + '</td>' +
          '<td class="px-5 py-3 text-gray-200 font-medium">' + d.content + '</td>' +
          '<td class="px-5 py-3">' + readStatus + '</td>' +
        '</tr>';
      }
      tbody.innerHTML = html;
    }

    async function loadAppeals() {
      var res = await fetch('/api/v1/admin/appeals');
      var appeals = await res.json();
      var tbody = document.getElementById('appeals-table-body');
      if (!appeals || appeals.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="px-5 py-8 text-center text-gray-500">No pending appeals found.</td></tr>';
        return;
      }
      var html = '';
      for (var i = 0; i < appeals.length; i++) {
        var a = appeals[i];
        var statusColor = a.status === 'pending' ? 'bg-amber-500/20 text-amber-400' : (a.status === 'approved' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-red-500/20 text-red-400');
        var decisionAction = a.status === 'pending'
          ? '<button onclick="resolveAppeal(\'' + a.id + '\', true)" class="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 text-xs font-semibold rounded text-white">Approve & Unban</button> ' +
            '<button onclick="resolveAppeal(\'' + a.id + '\', false)" class="px-3 py-1 bg-red-600/80 hover:bg-red-600 text-xs font-semibold rounded text-white">Deny</button>'
          : '<span class="text-xs text-gray-500">Processed</span>';

        html += '<tr>' +
          '<td class="px-5 py-3 text-xs text-gray-400 font-mono">' + new Date(a.createdAt).toLocaleDateString() + '</td>' +
          '<td class="px-5 py-3 font-mono text-xs text-gray-400">' + a.userId + '</td>' +
          '<td class="px-5 py-3 text-xs text-red-400">' + a.restrictionReason + '</td>' +
          '<td class="px-5 py-3 text-gray-200 italic font-serif">\"' + a.appealMessage + '\"</td>' +
          '<td class="px-5 py-3"><span class="px-2 py-0.5 text-xs rounded font-bold ' + statusColor + '">' + a.status.toUpperCase() + '</span></td>' +
          '<td class="px-5 py-3 text-right space-x-2">' + decisionAction + '</td>' +
        '</tr>';
      }
      tbody.innerHTML = html;
    }

    async function resolveAppeal(id, approve) {
      await fetch('/api/v1/admin/appeals/' + id + '/resolve?approve=' + approve, { method: 'POST' });
      loadAppeals();
      loadOverview();
    }

    function refreshAll() {
      switchTab(activeTab);
    }

    window.onload = function() {
      loadOverview();
    };
  </script>
</body>
</html>
`
