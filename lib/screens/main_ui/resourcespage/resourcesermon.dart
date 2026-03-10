import 'package:bethelprayerhouse/custom_widgets/text_widget.dart';
import 'package:bethelprayerhouse/screens/main_ui/shortspage/shorts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../custom_widgets/screen_size.dart';
import '../../../custom_widgets/top_search_widget.dart';
import '../../utils/colors.dart';

class ResourceSermonScreen extends StatefulWidget {
  const ResourceSermonScreen({super.key});

  @override
  State<ResourceSermonScreen> createState() => _ResourceSermonScreenState();
}

class _ResourceSermonScreenState extends State<ResourceSermonScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: getHeight(context),
      width: getWidth(context),
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/bg.png'), fit: BoxFit.cover)),
      child: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              const TopSearchWidget(show: true, backarrowshow: true),
              const SizedBox(height: 31),
               Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          TextWidget(
                              text: 'Sermons',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: whiteColor,
                              fontFamily: 'Poppins'),
                          
                          Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 31,
                                  width: 31,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: whiteColor),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Center(
                                      child: Icon(
                                    Icons.play_arrow,
                                    color: whiteColor,
                                  )),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 13,
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 20),
              for (int i = 0; i < 6; i++)
                SizedBox(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>const ShortsScreen()));
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          width: getWidth(context),
                          decoration: const BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage('assets/doe.png'),
                                  fit: BoxFit.cover)),
                          child: Center(
                            child: Container(
                              height: 31,
                              width: 31,
                              decoration: BoxDecoration(
                                border: Border.all(color: whiteColor),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                  child: Icon(
                                Icons.play_arrow,
                                color: whiteColor,
                              )),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(children: [
                              SvgPicture.asset('assets/blackbook.svg'),
                              const SizedBox(width: 10),
                              TextWidget(
                                  text: 'Trusting the Word Of God',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: blackColor,
                                  fontFamily: 'Poppins')
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              SvgPicture.asset('assets/blackperson.svg'),
                              const SizedBox(width: 10),
                              TextWidget(
                                  text: 'Pst John Doe',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: blackColor,
                                  fontFamily: 'Poppins')
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              SvgPicture.asset('assets/claritydate.svg'),
                              const SizedBox(width: 10),
                              TextWidget(
                                  text: '12-09-2023',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: blackColor,
                                  fontFamily: 'Poppins')
                            ]),
                            const SizedBox(height: 15),
                            TextWidget(
                                text:
                                    'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the indust standard dummy',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: blackColor,
                                fontFamily: 'Poppins'),
                            const SizedBox(height: 40),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: amberyellowColor),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60, vertical: 7),
                                child: TextWidget(
                                    text: 'Leave comment',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: amberyellowColor,
                                    fontFamily: 'Arial'),
                              ),
                            ),
                            const SizedBox(height: 55)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}
