import 'package:bethelprayerhouse/custom_widgets/screen_size.dart';
import 'package:bethelprayerhouse/custom_widgets/textfield_widget.dart';
import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool obscureText = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: getHeight(context),
        width: getWidth(context),
        color: whiteColor,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 40,
              ),
              SvgPicture.asset('assets/signup_icon.svg'),
              Text(
                'Hello!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: blackColor,
                    fontFamily: 'Roboto'),
              ),
              const SizedBox(
                height: 10,
              ),
             const TextFieldWidget(hintText: 'Name*', icon: Icons.person),
              const SizedBox(
                height: 20,
              ),
             const TextFieldWidget(hintText: 'Email*', icon: Icons.email),
              const SizedBox(
                height: 20,
              ),
              TextFieldWidget(
                hintText: 'Password',
                icon: Icons.lock_open,
                obscureText: obscureText,
                suffixicon: Icons.remove_red_eye,
              ),
              const SizedBox(
                height: 20,
              ),
              const TextFieldWidget(hintText: 'Phone', icon: Icons.phone),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(value: false, onChanged: (val) {}),
                  Text(
                    'I agree to all the ',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: greyTextColor,
                        fontFamily: 'Roboto'),
                  ),
                  Text(
                    'Terms & Conditions',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: blackColor,
                        fontFamily: 'Roboto'),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: gradientOne),
                  onPressed: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 10),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          color: whiteColor,
                          fontFamily: 'Roboto'),
                    ),
                  )),
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SvgPicture.asset('assets/Line.svg'),
                  Text(
                    'Or',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: blackColor,
                        fontFamily: 'Roboto'),
                  ),
                  SvgPicture.asset('assets/Line.svg'),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      height: 35,
                      width: 35,
                      child: SvgPicture.asset('assets/google_main.svg')),
                  const SizedBox(
                    width: 20,
                  ),
                  SizedBox(
                      height: 35,
                      width: 35,
                      child: SvgPicture.asset('assets/apple1.svg')),
                  const SizedBox(
                    width: 20,
                  ),
                  SizedBox(
                      height: 35,
                      width: 35,
                      child: SvgPicture.asset('assets/facebook.svg'))
                ],
              ),
              const SizedBox(
                height: 19,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: greyTextColor,
                        fontFamily: 'Roboto'),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Sing In',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: blackColor,
                          fontFamily: 'Roboto'),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
