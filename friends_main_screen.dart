import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsMainScreen extends StatefulWidget {
  const FriendsMainScreen({super.key});

  @override
  State<FriendsMainScreen> createState() => _FriendsMainScreenState();
}

class _FriendsMainScreenState extends State<FriendsMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> pendingRequests = [];
  List<Map<String, dynamic>> suggestedFriends = [];
  String? currentUserId;
  bool isLoading = false;

  final supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadSuggestedFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      currentUserId = user.id;
    });

    await _loadFriends();
    await _loadPendingRequests();
  }

  Future<void> _loadFriends() async {
    final uid = currentUserId;
    if (uid == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabase.from('friendships').select('''
            id, status, created_at,
            friend:profiles!friendships_friend_id_fkey(id, username, full_name, avatar_url, is_online)
          ''').eq('user_id', uid).eq('status', 'accepted');

      setState(() {
        friends = response;
      });
    } catch (e) {
      print('Arkadaşlar yüklenirken hata: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadPendingRequests() async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final response = await supabase.from('friendships').select('''
          id, status, created_at,
          sender:profiles!friendships_user_id_fkey(id, username, full_name, avatar_url, is_online)
        ''').eq('friend_id', uid).eq('status', 'pending');

      setState(() {
        pendingRequests = response;
      });
    } catch (e) {
      print('Bekleyen istekler yüklenirken hata: $e');
    }
  }

  Future<void> _loadSuggestedFriends() async {
    try {
      // Rastgele kullanıcı önerileri getir
      final response = await supabase
          .from('profiles')
          .select('id, username, full_name, avatar_url')
          .limit(10);

      setState(() {
        suggestedFriends = response;
      });
    } catch (e) {
      print('Önerilen arkadaşlar yüklenirken hata: $e');
    }
  }

  Future<void> _acceptFriendRequest(String requestId) async {
    try {
      // İsteği kabul et
      await supabase
          .from('friendships')
          .update({'status': 'accepted'}).eq('id', requestId);

      // Karşılıklı arkadaşlık ilişkisi oluştur
      final request =
          pendingRequests.firstWhere((req) => req['id'] == requestId);
      final senderId = request['sender']['id'];

      await supabase.from('friendships').insert({
        'user_id': currentUserId,
        'friend_id': senderId,
        'status': 'accepted',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Listeleri yenile
      await _loadFriends();
      await _loadPendingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Arkadaşlık isteği kabul edildi!"),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('İstek kabul hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("İstek kabul edilemedi: ${e.toString()}"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      await supabase.from('friendships').delete().eq('id', requestId);

      await _loadPendingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Arkadaşlık isteği reddedildi!"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("İstek reddedilemedi"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _searchUsers() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await supabase
          .from('profiles')
          .select('id, username, full_name, avatar_url')
          .ilike('username', '%${_searchController.text}%')
          .limit(10);

      setState(() {
        _searchResults.clear();
        _searchResults.addAll(response);
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arama sırasında hata oluştu: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Öncelikle bu kullanıcıya daha önce istek gönderilip gönderilmediğini kontrol et
      final existingRequests = await supabase
          .from('friendships')
          .select()
          .eq('user_id', currentUser.id)
          .eq('friend_id', userId);

      if (existingRequests.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bu kullanıcıya zaten istek gönderdiniz'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await supabase.from('friendships').insert({
        'user_id': currentUser.id,
        'friend_id': userId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Arkadaşlık isteği gönderildi'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arkadaşlık isteği gönderilemedi: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişiler',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? Colors.black : Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? Colors.white : Colors.black,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: isDark ? Colors.grey : Colors.grey[600],
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'İstekler'),
            Tab(text: 'Arkadaşlar'),
            Tab(text: 'Keşfet'),
          ],
        ),
      ),
      body: Container(
        color: isDark ? Colors.black : Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            // İstekler Sekmesi
            _buildRequestsTab(),

            // Arkadaşlar Sekmesi
            _buildFriendsTab(),

            // Keşfet Sekmesi
            _buildDiscoverTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadPendingRequests();
      },
      child: pendingRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bekleyen istek yok',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                final sender = request['sender'];
                return _buildRequestItem(sender, request['id']);
              },
            ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> user, String requestId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: user['avatar_url'] != null
                ? NetworkImage(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  user['full_name'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _acceptFriendRequest(requestId),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _rejectFriendRequest(requestId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadFriends();
      },
      child: friends.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz arkadaşın yok',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Arkadaş eklemek için Keşfet sekmesine göz at',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index]['friend'];
                return _buildFriendItem(friend);
              },
            ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: friend['avatar_url'] != null
                ? NetworkImage(friend['avatar_url'])
                : null,
            child: friend['avatar_url'] == null
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['username'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  friend['full_name'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.circle,
            color: friend['is_online'] ? Colors.green : Colors.grey,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Arama Çubuğu
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Kullanıcı adı ara...',
              prefixIcon: const Icon(Iconsax.search_normal),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (value) => _searchUsers(),
          ),
        ),

        // Arama Sonuçları veya Önerilenler
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return _buildDiscoverItem(user);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: suggestedFriends.length,
                      itemBuilder: (context, index) {
                        final user = suggestedFriends[index];
                        return _buildDiscoverItem(user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDiscoverItem(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: user['avatar_url'] != null
                ? NetworkImage(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  user['full_name'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _sendFriendRequest(user['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Takip Et'),
          ),
        ],
      ),
    );
  }
}
