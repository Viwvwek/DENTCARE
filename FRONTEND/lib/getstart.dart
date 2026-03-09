import 'package:flutter/material.dart';
import 'package:dentcare/login.dart';

class Getstart extends StatelessWidget {
  const Getstart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient (Replaces backgroundColor: Colors.black87)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                   Color(0xFF4FD1C5), // Top Teal
                   Color(0xFF38B2AC), // Bottom Teal
                ],
              ),
            ),
          ),
          
          // 2. Background Lines (Kept to ensure it looks "exact" as requested)
          CustomPaint(
            painter: BackgroundLinePainter(),
          ),

          // 3. Main Content using your pattern (SingleScroll -> Padding -> Column)
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to left
                children: [
                  // Title Text
                  const Padding(
                    padding: EdgeInsets.only(left: 24.0),
                    child: Text(
                      "DentCare",
                      style: TextStyle(
                        fontSize: 24, 
                        color: Colors.white, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),

                  // 3D Image Container
                  const SizedBox(height: 20), // Space between title and image
                  Padding(
                    padding: const EdgeInsets.only(top: 60, bottom: 40),
                    child: SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: Image.asset(
                        "assets/images/First_Aid-removebg-preview.png", // Make sure to add this asset
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Bottom Card Section
                  const SizedBox(height: 150),   // ⬇️ This moves the button down

Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
  child: Container(
    margin: const EdgeInsets.only(top: 30),
    height: 100,
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF81E6D9).withOpacity(1.0),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: MaterialButton(
          onPressed: () {  
            Navigator.push(context, MaterialPageRoute(builder: (context)=>const Login()));
          },
          height: 55,
          minWidth: 220,
          color: Colors.white,
          child: const Text(
            "Get Started",
            style: TextStyle(
              color: Color(0xFF319795),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  ),
),

                ],
              ),
            ),
          ),
        ],
      ),

    );
  }                                         
}
class BackgroundLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(size.width * 0.7, 0);
    path.cubicTo(
      size.width * 0.9, size.height * 0.2,
      size.width * 0.2, size.height * 0.4,
      size.width * 0.1, size.height * 0.6,
    );
    path.cubicTo(
      size.width * 0.05, size.height * 0.75,
      size.width * 0.4, size.height * 0.85,
      size.width * 0.8, size.height * 0.95,
    );
    path.quadraticBezierTo(
      size.width * 0.95, size.height, 
      size.width, size.height * 0.9
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
