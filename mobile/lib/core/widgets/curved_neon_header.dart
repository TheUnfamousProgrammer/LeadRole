import 'package:flutter/material.dart';
import '../../shared/colors.dart';

class CurvedNeonHeader extends StatelessWidget {
  final Widget child;
  const CurvedNeonHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        color: AppColors.neon,
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.70,
        child: child,
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 80)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height,
        size.width,
        size.height - 80,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BottomCurveClipper oldClipper) => false;
}
