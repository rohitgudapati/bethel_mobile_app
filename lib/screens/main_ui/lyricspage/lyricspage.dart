import 'package:bethelprayerhouse/custom_widgets/top_search_widget.dart';
import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../custom_widgets/text_widget.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  String dropdownvalue = 'Item 1';
  // ignore: non_constant_identifier_names
  var Items = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/bg.png'), fit: BoxFit.cover)),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                const TopSearchWidget(show: true, backarrowshow: true),
                const SizedBox(height: 27),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 22),
                          decoration: BoxDecoration(
                            border: Border.all(color: blackColor),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 9),
                            child: Row(
                              children: [
                                SvgPicture.asset('assets/globe.svg'),
                                const SizedBox(width: 8),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton(
                                    value: dropdownvalue,
                                    items: Items.map((String items) {
                                      return DropdownMenuItem(
                                        value: items,
                                        child: Text(items),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        dropdownvalue = newValue!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: whiteColor),
                            child: Icon(
                              Icons.music_note_outlined,
                              color: blackColor,
                            )),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            child: Column(children: [
                              SvgPicture.asset('assets/saved.svg'),
                              TextWidget(
                                  text: 'Saved',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: blackColor,
                                  fontFamily: 'Poppins')
                            ]),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            child: Column(children: [
                              SvgPicture.asset('assets/download.svg'),
                              TextWidget(
                                  text: 'Downloads',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: blackColor,
                                  fontFamily: 'Poppins')
                            ]),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            child: Column(children: [
                              SvgPicture.asset('assets/share.svg'),
                              TextWidget(
                                  text: 'Share',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: blackColor,
                                  fontFamily: 'Poppins')
                            ]),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 17),
                      child: Image.asset('assets/lyrics.png', fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextWidget(
                                text: 'Title:',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: blackColor,
                                fontFamily: 'Poppins'),
                            TextWidget(
                                text: 'Aadhaaram Naaku Aadhaaram',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: gradientOne,
                                fontFamily: 'Poppins'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextWidget(
                                text: 'Lyricist:',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: blackColor,
                                fontFamily: 'Poppins'),
                            TextWidget(
                                text: 'Bonigala Babu Rao',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: gradientOne,
                                fontFamily: 'Poppins'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextWidget(
                            text: 'Aadhaaram Naaku Aadhaaram Naaku Thodu Needai Unna Nee Krupaye Aadhaaram Aashrayamu Naaku Aashrayamu Aapathkaalamandu Aashrayamu Nee Naamam Aashrayamu Thalli Thandri Lekunnaa – Bandhu Janulu Raakunaa Lokamantha Okatainaa – Baadhalanni Bandhuvulainaa  ',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                            const SizedBox(height: 30),
                            TextWidget(
                            text: 'Aadhaaram Naaku Aadhaaram Naaku Thodu Needai Unna Nee Krupaye Aadhaaram Aashrayamu Naaku Aashrayamu Aapathkaalamandu Aashrayamu Nee Naamam Aashrayamu Thalli Thandri Lekunnaa – Bandhu Janulu Raakunaa Lokamantha Okatainaa – Baadhalanni Bandhuvulainaa  ',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                            const SizedBox(height: 30),
                            TextWidget(
                            text: 'Aadhaaram Naaku Aadhaaram Naaku Thodu Needai Unna Nee Krupaye Aadhaaram Aashrayamu Naaku Aashrayamu Aapathkaalamandu Aashrayamu Nee Naamam Aashrayamu Thalli Thandri Lekunnaa – Bandhu Janulu Raakunaa Lokamantha Okatainaa – Baadhalanni Bandhuvulainaa  ',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                            const SizedBox(height: 30),
                            TextWidget(
                            text: 'Aadhaaram Naaku Aadhaaram Naaku Thodu Needai Unna Nee Krupaye Aadhaaram Aashrayamu Naaku Aashrayamu Aapathkaalamandu Aashrayamu Nee Naamam Aashrayamu Thalli Thandri Lekunnaa – Bandhu Janulu Raakunaa Lokamantha Okatainaa – Baadhalanni Bandhuvulainaa  ',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                            const SizedBox(height: 30),
                            TextWidget(
                            text: 'Aadhaaram Naaku Aadhaaram Naaku Thodu Needai Unna Nee Krupaye Aadhaaram Aashrayamu Naaku Aashrayamu Aapathkaalamandu Aashrayamu Nee Naamam Aashrayamu Thalli Thandri Lekunnaa – Bandhu Janulu Raakunaa Lokamantha Okatainaa – Baadhalanni Bandhuvulainaa  ',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                            const SizedBox(height: 30),
                            TextWidget(
                            text: 'Aadhaaram Naaku Aadhaaram Naaku Thodu Needai Unna Nee Krupaye Aadhaaram Aashrayamu Naaku Aashrayamu Aapathkaalamandu Aashrayamu Nee Naamam Aashrayamu Thalli Thandri Lekunnaa – Bandhu Janulu Raakunaa Lokamantha Okatainaa – Baadhalanni Bandhuvulainaa  ',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                            const SizedBox(height: 30),
                            TextWidget(
                            text: 'Aadhaaram Naaku Aadhaaram Naaku Thodu Needai Unna Nee Krupaye Aadhaaram Aashrayamu Naaku Aashrayamu Aapathkaalamandu Aashrayamu Nee Naamam Aashrayamu Thalli Thandri Lekunnaa – Bandhu Janulu Raakunaa Lokamantha Okatainaa – Baadhalanni Bandhuvulainaa  ',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                            const SizedBox(height: 30),
                      ],
                    ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
