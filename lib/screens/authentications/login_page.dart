import 'package:bethelprayerhouse/custom_widgets/screen_size.dart';
import 'package:bethelprayerhouse/custom_widgets/textfield_widget.dart';
import 'package:bethelprayerhouse/screens/authentications/signup_page.dart';
import 'package:bethelprayerhouse/screens/main_ui/bottom_page.dart';
import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: whiteColor,
      ),
      body: SizedBox(
        height: getHeight(context),
        width: getWidth(context),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/bethel_logo.png'),
              const SizedBox(
                height: 16,
              ),
              Text('Bethel prayer house'.toUpperCase(),style: TextStyle(
                fontSize: 20,fontWeight: FontWeight.w400,color: blackColor,fontFamily: "Quintessential"
              ),),
              const SizedBox(
                height: 64,
              ),
              Text('Welcome Back!',style: TextStyle(
                fontSize: 20,fontWeight: FontWeight.w700,color: blackColor,fontFamily: 'Poppins'
              ),),
             const SizedBox(
                height: 42,
              ),
            const TextFieldWidget(hintText: 'Name Or Email', icon: Icons.person,),
            const SizedBox(
              height: 24,
            ),
            const TextFieldWidget(hintText: 'Password', icon: Icons.lock_open_outlined,),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: (){}, child: Text('Forgot Password?',style: TextStyle(
                    fontSize: 15,fontWeight: FontWeight.w300,color: blackColor,fontFamily: 'Roboto'
                  ),))
                ],
              ),
            ),
            const SizedBox(
              height: 29,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: gradientOne),
              onPressed: (){
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=> const BottomPage()), (route) => false);
              }, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60,vertical: 10),
                child: Text('Sign In',style: TextStyle(
                fontSize: 21,fontWeight: FontWeight.w400,color: whiteColor,fontFamily: 'Roboto'
                          ),),
              )),
              const SizedBox(
                height: 34,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SvgPicture.asset('assets/Line.svg'),
                  Text('Or',style: TextStyle(
                    fontSize: 15,fontWeight: FontWeight.w300,color: blackColor,fontFamily: 'Roboto'
                  ),),
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
                  Text('Dont’t have on account ',style: TextStyle(
                    fontSize: 15,fontWeight: FontWeight.w400,color: greyTextColor,fontFamily: 'Roboto'
                  ),),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_)=> const SignUpScreen()));  
                    },
                    child: Text('Sing Up',style: TextStyle(
                      fontSize: 15,fontWeight: FontWeight.w700,color: blackColor,fontFamily: 'Roboto'
                    ),),
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

