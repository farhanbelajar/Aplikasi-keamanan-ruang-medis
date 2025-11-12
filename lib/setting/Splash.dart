import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:skripsi_hangans/setting/MainPage.dart';
import 'package:skripsi_hangans/setting/TextWidget.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool position = false;
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => animator());
  }

  void animator() async {
    setState(() {
      opacity = 1;
      position = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              top: position ? 60 : 150,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 20),
                    TextWidget("Keamanan", 35, Colors.black, FontWeight.bold, letterSpace: 5),
                    SizedBox(height: 5),
                    TextWidget("Akses", 35, Colors.black, FontWeight.bold, letterSpace: 5),
                    SizedBox(height: 5),
                    TextWidget("Ruang Medis", 35, Colors.black, FontWeight.bold, letterSpace: 5),
                    SizedBox(height: 20),
                    TextWidget("Muhammad\nFarhan", 18, Colors.black54, FontWeight.bold),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              bottom: 1,
              left: position ? 50 : 150,
              duration: const Duration(milliseconds: 400),
              child: AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  height: 450,
                  width: 400,
                  child: Lottie.asset(
                    'assets/depan.json', // pastikan file ini ada dan sudah terdaftar di pubspec.yaml
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              bottom: 60,
              left: position ? 20 : -100,
              duration: const Duration(milliseconds: 400),
              child: AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 400),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      opacity = 0;
                      position = false;
                    });
                    Timer(const Duration(milliseconds: 400), () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Mainpage()),
                      );
                    });
                  },
                  child: Container(
                    width: 150,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: TextWidget("Get Started", 17, Colors.white, FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
