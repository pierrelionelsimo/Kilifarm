import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/story_repository.dart';

/// Sélection d'une photo depuis la galerie (le sélecteur s'ouvre dès
/// l'arrivée sur l'écran), aperçu plein écran, puis publication.
/// Même compression qu'à la création d'un post (imageQuality: 70,
/// maxWidth: 1280) — connexions lentes en zone rurale.
class CreateStoryScreen extends StatefulWidget {
  final StoryRepository storyRepository;

  const CreateStoryScreen({super.key, required this.storyRepository});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _image;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pick());
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
    );

    if (picked == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (mounted) setState(() => _image = File(picked.path));
  }

  Future<void> _post() async {
    if (_image == null || _isPosting) return;
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() => _isPosting = true);

    try {
      await widget.storyRepository.createStory(
        userId: user.uid,
        userName: user.fullName,
        image: _image!,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi de la story")),
        );
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_image != null)
              Positioned.fill(child: Image.file(_image!, fit: BoxFit.contain)),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_image != null)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: _isPosting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton.icon(
                          onPressed: _post,
                          icon: const Icon(Icons.send),
                          label: const Text('Partager en story'),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
