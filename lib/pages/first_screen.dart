import 'dart:async';
import 'package:appish/pages/second_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  int _dotCount = 5;
  int _currentindex = 0;
  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 5));
  }

  void initState() {
    super.initState();
    _loadData().then((value) => {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SecondScreen()))
        });
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_currentindex < _dotCount) {
        setState(() {
          _currentindex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: 30.h,
            ),
            Center(
              child: Column(
                children: [
                  Text(
                    'ISLAMIC',
                    style: TextStyle(
                        fontSize: 30.sp,
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'RINGTONES',
                    style: TextStyle(
                        fontSize: 25.sp,
                        color: Colors.white,
                        fontFamily: 'sans_regular'),
                  ),
                  Image.asset(
                    'asset/images/line2.png',
                    width: 270.h,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(width: 5.w, color: Colors.white),
                      right: BorderSide(width: 5.w, color: Colors.white),
                      top: BorderSide(width: 5.w, color: Colors.white),
                      bottom: BorderSide(width: 5.w, color: Colors.white)),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Image.asset(
                  'asset/images/mice.jfif',
                  height: 150.h,
                  width: 150.w,
                ),
              ),
            ),
            SizedBox(
              height: 20.h,
            ),
            Center(
              child: Text(
                'Islamic Ringtones',
                style: TextStyle(
                    fontSize: 30.sp,
                    color: Colors.white,
                    fontFamily: 'sans_regular'),
              ),
            ),
            Center(
              child: Text(
                'Multiple collections',
                style: TextStyle(fontSize: 25.sp, color: Colors.yellow),
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            Center(
              child: Image.asset(
                'asset/images/Quran1.png',
                width: 100.w,
                height: 100.h,
              ),
            ),
            SizedBox(
              height: 30.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Loading',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontFamily: 'sans_regular',
                      fontWeight: FontWeight.w100),
                ),
                SizedBox(
                  width: 10.w,
                ),
                Row(
                    children: List.generate(
                        _dotCount,
                        (index) => Container(
                              height: 10.h,
                              width: 10.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentindex
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            )))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
