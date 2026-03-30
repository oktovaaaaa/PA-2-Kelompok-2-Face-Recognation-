import 'package:flutter/material.dart';

class WavyBackground extends StatelessWidget {
  final Widget child;
  final bool isAuth;

  const WavyBackground({
    super.key,
    required this.child,
    this.isAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Latar belakang dasar
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Ombak Vektor (CustomPainter)
          Positioned.fill(
            child: CustomPaint(
              painter: _WavyBackgroundPainter(),
            ),
          ),
          
          // Bola bercahaya besar (kiri bawah)
          Positioned(
            left: -50,
            bottom: isAuth ? 40 : -50,
            child: _buildSphere(
              size: 160,
              colors: [const Color(0xFF1D4ED8), const Color(0xFF1E3A8A)],
              blurRadius: 30,
            ),
          ),
          
          // Bola terang (kanan atas)
          Positioned(
            right: -20,
            top: 100,
            child: _buildSphere(
              size: 100,
              colors: [Colors.blue.shade300, const Color(0xFF2563EB)],
              blurRadius: 20,
            ),
          ),
          
          // Bola gelap (kiri atas)
          Positioned(
            left: -40,
            top: -20,
            child: _buildSphere(
              size: 120,
              colors: [const Color(0xFF0F172A), const Color(0xFF1E3A8A)],
              blurRadius: 40,
            ),
          ),
          
          // Konten Utama
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSphere({
    required double size,
    required List<Color> colors,
    required double blurRadius,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.5),
            blurRadius: blurRadius,
            offset: const Offset(10, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: blurRadius / 2,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
    );
  }
}

class _WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ombak 1
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(
      size.width * 0.25, size.height * 0.45,
      size.width * 0.5, size.height * 0.35,
    );
    path1.quadraticBezierTo(
      size.width * 0.75, size.height * 0.25,
      size.width, size.height * 0.4,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.2),
          const Color(0xFF3B82F6).withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawPath(path1, paint1);

    // Ombak 2
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.2, size.height * 0.6,
      size.width * 0.4, size.height * 0.75,
    );
    path2.quadraticBezierTo(
      size.width * 0.7, size.height * 0.9,
      size.width, size.height * 0.65,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0F172A).withOpacity(0.4),
          const Color(0xFF1E3A8A).withOpacity(0.2),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
