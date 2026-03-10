import 'dart:async';

import 'package:bethelprayerhouse/custom_widgets/screen_size.dart';
import 'package:bethelprayerhouse/screens/authentications/login_page.dart';
import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer( const Duration(seconds: 3), () { 
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=> const LoginPage()), (route) => false);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: getHeight(context),
        width: getWidth(context),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
            gradientOne,
            gradientTwo
          ])
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          SizedBox(
           
            width: getWidth(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/bethel_logo.png'),
                const SizedBox(
                  width: 14,
                ),
                Column(
                  children: [
                    Text('Bethel'.toUpperCase(),style: TextStyle(
                      fontSize: 52,fontWeight: FontWeight.w400,color: whiteColor,fontFamily: 'Quintessential'
                    ),),
                      Text('prayer house'.toUpperCase(),style: TextStyle(
                      fontSize: 24,fontWeight: FontWeight.w400,color: whiteColor,fontFamily: 'Quintessential'
                    ),)
                  ],
                )
              ],
            ),
          )
          ],
        ),
      ),
    );
  }
}