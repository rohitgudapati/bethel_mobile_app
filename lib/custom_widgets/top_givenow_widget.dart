import 'package:bethelprayerhouse/custom_widgets/screen_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../screens/utils/colors.dart';

class TopGiveNowWidget extends StatelessWidget {
  const TopGiveNowWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 23),
      width: getWidth(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            child: Row(
              children: [
                Text(
                  'Bethel',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: blackColor,
                      fontFamily: 'Poppins',
                      decoration: TextDecoration.underline),
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  'Hebron',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: greyTextColor,
                    fontFamily: 'Poppins',
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            child: Row(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: whiteColor,
                  ),
                  child: Icon(
                    Icons.search,
                    color: blackColor,
                  ),
                ),
                const SizedBox(
                  width: 08,
                ),
                Container(
                  padding: const EdgeInsets.all(08),
                  decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: const BorderRadius.all(
                          Radius.circular(30))),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/heart.svg'),
                      const SizedBox(
                        width: 02,
                      ),
                      Text(
                        'GiveNow',
                        style: TextStyle(
                            fontSize: 06,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
