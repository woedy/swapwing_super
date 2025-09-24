import 'package:flutter/material.dart';
import 'package:swapwing/screens/auth/login_screen.dart';
import 'package:swapwing/screens/main_navigation.dart';
import 'package:swapwing/screens/onboarding/onboarding_screen.dart';
import 'package:swapwing/services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification code.')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await AuthService.verifyEmail(email: widget.email, code: code);

      if (!mounted) return;

      final hasCompletedOnboarding = await AuthService.hasCompletedOnboarding();
      final nextScreen =
          hasCompletedOnboarding ? const MainNavigation() : const OnboardingScreen();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => nextScreen),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'email_already_verified') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your email is already verified. Please sign in.'),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (_) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not verify your email. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);

    try {
      await AuthService.resendVerificationEmail(widget.email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email resent to ${widget.email}.'),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resend verification email.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check your inbox',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a verification code to\n${widget.email}. Enter the code below to activate your account.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying
                    ? const CircularProgressIndicator.adaptive()
                    : const Text('Verify Email'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive it?",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: _isResending ? null : _resendVerification,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend email'),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (_) => false,
                  );
                },
                child: const Text('Back to login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
