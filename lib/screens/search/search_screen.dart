import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/firestore_user_repository.dart';
import '../../widgets/initials_avatar.dart';
import '../profile/public_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final UserRepository _userRepository = FirestoreUserRepository();
  final TextEditingController _nameController = TextEditingController();

  List<UserModel> _allResults = []; // filtré région/activité (côté serveur)
  List<UserModel> _displayedResults = []; // + filtré nom (côté client)
  String? _selectedRegion;
  String? _selectedActivityType;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_applyNameFilter);
    _loadResults();
  }

  @override
  void dispose() {
    _nameController.removeListener(_applyNameFilter);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = context.read<AuthProvider>().userModel?.uid;
      final results = await _userRepository.searchUsers(
        region: _selectedRegion,
        activityType: _selectedActivityType,
        excludeUserId: currentUserId,
      );
      _allResults = results;
      _applyNameFilter();
    } catch (e) {
      _errorMessage = "Impossible de charger l'annuaire.";
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyNameFilter() {
    final query = _nameController.text.trim().toLowerCase();
    setState(() {
      _displayedResults = query.isEmpty
          ? _allResults
          : _allResults
              .where((u) => u.fullName.toLowerCase().contains(query))
              .toList();
    });
  }

  void _toggleRegion(String region) {
    setState(() => _selectedRegion = _selectedRegion == region ? null : region);
    _loadResults();
  }

  void _toggleActivityType(String type) {
    setState(
        () => _selectedActivityType = _selectedActivityType == type ? null : type);
    _loadResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nom...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.cardWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: AppConstants.cameroonRegions.map((region) {
                final selected = _selectedRegion == region;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(region),
                    selected: selected,
                    onSelected: (_) => _toggleRegion(region),
                    selectedColor: AppTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppTheme.textDark,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: AppConstants.activityTypes.map((type) {
                final selected = _selectedActivityType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => _toggleActivityType(type),
                    selectedColor: AppTheme.accentOrange,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppTheme.textDark,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 40, color: AppTheme.textLight),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  style: const TextStyle(color: AppTheme.textLight)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadResults,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_displayedResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun utilisateur trouvé avec ces critères.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textLight),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _displayedResults.length,
      itemBuilder: (context, index) {
        final user = _displayedResults[index];
        return ListTile(
          leading: InitialsAvatar(fullName: user.fullName, radius: 20),
          title: Text(user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            [
              if (user.activityType != null && user.activityType!.isNotEmpty)
                user.activityType!,
              if (user.region != null && user.region!.isNotEmpty) user.region!,
            ].join(' · '),
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PublicProfileScreen(user: user)),
            );
          },
        );
      },
    );
  }
}
