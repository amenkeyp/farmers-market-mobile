import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_controller.dart';
import 'widgets/login_painters.dart';

// ── Spec gradient colours ────────────────────────────────
const _kGradientStart = Color(0xFF0A84FF);
const _kGradientEnd = Color(0xFF0066CC);
const _kWaveHeightFraction = 0.48;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _pwd.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(_email.text.trim(), _pwd.text);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err ?? 'Échec de la connexion')));
    }
  }

  Future<void> _demoLogin() async {
    _email.text = 'admin@market.ci';
    _pwd.text = 'password';
    final ok = await ref
        .read(authControllerProvider.notifier)
        .login('admin@market.ci', 'password');
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Échec de la connexion demo')),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Layer 1: wave-clipped gradient + pattern ────
          _buildWaveHeader(size),

          // ── Layer 2: scrollable content ─────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildAppIcon(),
                      const SizedBox(height: 20),
                      _buildTitle(),
                      const SizedBox(height: 10),
                      _buildSubtitle(),
                      const SizedBox(height: 36),
                      _buildFormCard(state),
                      const SizedBox(height: 28),
                      _buildOrDivider(),
                      const SizedBox(height: 20),
                      _buildDemoButton(state),
                      const SizedBox(height: 32),
                      _buildFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wave header ────────────────────────────────────────

  Widget _buildWaveHeader(Size size) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: size.height * _kWaveHeightFraction,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kGradientStart, _kGradientEnd],
          ),
        ),
        child: CustomPaint(
          painter: HeaderPatternPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }

  // ── App icon ───────────────────────────────────────────

  Widget _buildAppIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kGradientEnd.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }

  // ── Title ──────────────────────────────────────────────

  Widget _buildTitle() {
    return const Text(
      'Marché POS',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }

  // ── Subtitle ───────────────────────────────────────────

  Widget _buildSubtitle() {
    return Text(
      'Gérez vos ventes, vos clients et\nvos crédits en toute simplicité.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  // ── Form card ──────────────────────────────────────────

  Widget _buildFormCard(AuthState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card heading ───────────────────────────
            const Text(
              'Connexion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connectez-vous à votre compte',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),

            // ── Email field ────────────────────────────
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'admin@market.ci',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: 16),

            // ── Password field ─────────────────────────
            TextFormField(
              controller: _pwd,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 4)
                  ? 'Mot de passe trop court'
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Remember me + Forgot password ──────────
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    activeColor: _kGradientStart,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Se souvenir de moi',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kGradientStart,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Login button ───────────────────────────
            PrimaryButton(
              label: 'Se connecter',
              icon: Icons.login_rounded,
              loading: state.loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  // ── Or divider ─────────────────────────────────────────

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.textTertiary.withValues(alpha: 0.3)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.textTertiary.withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  // ── Demo button ────────────────────────────────────────

  Widget _buildDemoButton(AuthState state) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: state.loading ? null : _demoLogin,
        icon: const Icon(Icons.person_outline_rounded),
        label: const Text('Demo (accès rapide)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kGradientStart,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────

  Widget _buildFooter() {
    return const Text(
      'v1.0 • Farmers Market Platform',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
    );
  }
}
