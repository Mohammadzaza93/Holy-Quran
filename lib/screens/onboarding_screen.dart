import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// شاشة ترحيب لأول تشغيل باستخدام introduction_screen.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    await StorageService.instance.setOnboardingDone(true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  PageViewModel _page({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return PageViewModel(
      title: title,
      body: body,
      image: Center(
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 52, color: AppColors.primary),
        ),
      ),
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        bodyTextStyle: TextStyle(fontSize: 16, height: 1.7),
        imagePadding: EdgeInsets.only(top: 48),
        bodyPadding: EdgeInsets.symmetric(horizontal: 20),
        titlePadding: EdgeInsets.only(top: 24, bottom: 12),
        pageColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      pages: [
        _page(
          icon: Icons.play_circle_fill_rounded,
          title: 'تعلّم',
          body:
              'شاهد حلقات شرح التجويد المصور للشيخ أيمن سويد على يوتيوب بالترتيب.',
        ),
        _page(
          icon: Icons.quiz_rounded,
          title: 'اختبر',
          body:
              'راجع أحكام التجويد برواية حفص عبر أسئلة متنوعة ومراجعة ذكية للأخطاء.',
        ),
        _page(
          icon: Icons.mic_rounded,
          title: 'سمّع',
          body:
              'اقرأ الآية والتصحيح يتابعك كلمة بكلمة — مجاناً وعلى جهازك قدر الإمكان.',
        ),
      ],
      onDone: () => _finish(context),
      onSkip: () => _finish(context),
      showSkipButton: true,
      skip: const Text('تخطي', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      done: const Text('ابدأ', style: TextStyle(fontWeight: FontWeight.w800)),
      curve: Curves.easeOutCubic,
      dotsDecorator: DotsDecorator(
        size: const Size(8, 8),
        activeSize: const Size(22, 8),
        activeColor: AppColors.primary,
        color: AppColors.primary.withOpacity(0.28),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      controlsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
    );
  }
}
