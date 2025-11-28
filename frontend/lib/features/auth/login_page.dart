import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/sizes.dart';
import '../../core/typography.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 450),
          offset: _isVisible ? Offset.zero : const Offset(0, 0.08),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _isVisible ? 1 : 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingXL,
                vertical: AppSizes.paddingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFDBEAFE), Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to Smart Gram AI',
                style: AppTypography.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'वैयक्तिक सहाय्यक तुमच्या सेवेत',
                style: AppTypography.marathiHeadline(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () => context.go('/register'),
                child: authState.isLoading
                    ? const CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Sign Up'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  foregroundColor: AppColors.primary,
                ),
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .login(_emailController.text, _passwordController.text);
                        if (!mounted) return;
                        context.go('/home');
                      },
                child: authState.isLoading
                    ? const CircularProgressIndicator.adaptive(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      )
                    : const Text('Login'),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


