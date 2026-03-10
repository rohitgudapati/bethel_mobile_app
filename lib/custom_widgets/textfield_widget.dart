import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final IconData? suffixicon;
  final bool obscureText ;
  const TextFieldWidget({
    super.key,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixicon

  });

  @override
  Widget build(BuildContext context) {
    return Container(
     margin: const EdgeInsets.symmetric(horizontal: 23),
     height: 46,
      child: TextFormField(
        obscureText: obscureText,
       textInputAction: TextInputAction.next,
       style: TextStyle(
         fontSize: 15,fontWeight: FontWeight.w300,color: greyTextColor,fontFamily: 'Poppins'
       ),
       decoration: InputDecoration(
        suffixIcon: Icon(suffixicon,color: greyTextColor,),
         prefixIcon: Icon(icon,color: greyTextColor,),
         contentPadding: const EdgeInsets.only(top: 10,left: 10),
         hintText: hintText,
         hintStyle: TextStyle(
         fontSize: 15,fontWeight: FontWeight.w300,color: greyTextColor,fontFamily: 'Poppins'
       ),
         border: OutlineInputBorder(
           borderSide: BorderSide(color: greyTextColor),
           borderRadius: const BorderRadius.all(Radius.circular(60))
         ),
         enabledBorder:  OutlineInputBorder(
           borderSide: BorderSide(color: greyTextColor),
           borderRadius: const BorderRadius.all(Radius.circular(60))
         ),
         focusedBorder:  OutlineInputBorder(
             borderSide: BorderSide(color: greyTextColor),
           borderRadius: const BorderRadius.all(Radius.circular(60))
         )
       ),
      ),
    );
  }
}