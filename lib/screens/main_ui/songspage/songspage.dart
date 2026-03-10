import 'package:bethelprayerhouse/custom_widgets/text_widget.dart';
import 'package:bethelprayerhouse/custom_widgets/top_givenow_widget.dart';
import 'package:bethelprayerhouse/screens/main_ui/lyricspage/lyricspage.dart';
import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../custom_widgets/top_search_widget.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
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
                const TopGiveNowWidget(),
                const SizedBox(height: 10),
                const TopSearchWidget(show: false,backarrowshow: false),
                const SizedBox(height: 25),
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 23),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            TextWidget(
                                text: 'Recently Viewed',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                                fontFamily: 'Poppins'),
                          ]),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < 10; i++)
                              Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 17),
                                    child: Image.asset('assets/master1.png',
                                        fit: BoxFit.cover),
                                  ),
                                  const SizedBox(height: 5),
                                  TextWidget(
                                      text: 'Master Of God',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: blackColor,
                                      fontFamily: 'Poppins'),
                                  TextWidget(
                                      text: ' Jimmy Son',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: blackColor,
                                      fontFamily: 'Poppins'),
                                ],
                              )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 23),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                    text: 'Trending',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: blackColor,
                                    fontFamily: 'Poppins'),
                                TextWidget(
                                    text: 'View More',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: gradientOne,
                                    fontFamily: 'Poppins'),
                              ]),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (int i = 0; i < 10; i++)
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 17),
                                        child: Image.asset('assets/godsplan.png',
                                            fit: BoxFit.cover),
                                      ),
                                      const SizedBox(height: 5),
                                      TextWidget(
                                          text: "God's Plan",
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: blackColor,
                                          fontFamily: 'Poppins'),
                                      TextWidget(
                                          text: 'Bro.Mathew',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: blackColor,
                                          fontFamily: 'Poppins'),
                                    ],
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 23),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                                text: 'Songs Of Zion',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                                fontFamily: 'Poppins'),
                            SizedBox(
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
                            )
                          ]),
                    ),
                    const SizedBox(height: 28),
                    for(int i=0; i<10 ;i++)
                     Container(
                      margin: const EdgeInsets.symmetric(vertical: 30),
                       padding: const EdgeInsets.only(left: 23,right: 10),
                       child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                        TextWidget(
                                            text: "Aagi Mandimchu",
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: blackColor,
                                            fontFamily: 'Poppins'),
                                            const SizedBox(height: 10),
                                             TextWidget(
                                            text: "Manoju Varma , Karthik - Songs Of Zion",
                                            fontSize: 8,
                                            fontWeight: FontWeight.w400,
                                            color: blackColor,
                                            fontFamily: 'Poppins'),
                                      ],
                          ),
                          Row(
                            children: [
                              Container(
                                height: 35,
                                width: 35,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: whiteColor),
                                child: Icon(Icons.play_arrow,color: blackColor,)
                              ),
                              const SizedBox(width: 7),
                              InkWell(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>LyricsScreen()));
                                },
                                child: Container(
                                  height: 35,
                                  width: 35,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: whiteColor),
                                  child: Icon(Icons.music_note_outlined,color: blackColor,)
                                  // SvgPicture.asset('assets/listmusic.svg',height: 16,width: 10),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                height: 35,
                                width: 35,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: whiteColor),
                                child: Icon(Icons.remove_red_eye,color: blackColor,),
                              ),
                               const SizedBox(width: 8),
                              SizedBox(
                                child: SvgPicture.asset('assets/3dots.svg',height: 16,width: 10),
                              ),
                            ],
                          ),
                        ],
                                       ),
                     )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}


