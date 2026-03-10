import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopSearchWidget extends StatelessWidget {
  final bool show;
  final bool backarrowshow;
  const TopSearchWidget({
    super.key,
    required this.show,
    required this.backarrowshow
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Visibility(
          visible: backarrowshow,
          child: Expanded(
            flex: 1,
            child: SvgPicture.asset('assets/backarrow.svg')),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(left: 21, right: 8),
            child: Container(
              height: 37,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(blurRadius: 6, color: greyTextColor)
                  ],
                  color: whiteColor),
              child: TextFormField(
                cursorHeight: 16,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: whiteColor,
                    
                    contentPadding: const EdgeInsets.only(top: 10),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: whiteColor),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: whiteColor),
                        borderRadius: BorderRadius.circular(10.0)),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: whiteColor),
                        borderRadius: BorderRadius.circular(10.0)),
                    prefixIcon:
                        Icon(Icons.search, color: greyTextColor),
                    hintText: 'Search a song..',
                    hintStyle: TextStyle(color: greyTextColor)),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(blurRadius: 6, color: greyTextColor)
            ], shape: BoxShape.circle, color: whiteColor),
            child: Center(child: SvgPicture.asset('assets/microphone.svg')),
          ),
        ),
       const SizedBox(width: 7),
        Expanded(flex: 1, child: Visibility(
          visible: show,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(blurRadius: 6,color: greyTextColor)
            ],shape: BoxShape.circle,color: whiteColor
            ),
            child: Center(child: SvgPicture.asset('assets/3dots.svg'),),
          ),
        ))  
      ],
    );
  }
}