import 'package:bethelprayerhouse/custom_widgets/text_widget.dart';
import 'package:bethelprayerhouse/custom_widgets/top_search_widget.dart';
import 'package:bethelprayerhouse/screens/main_ui/bookspage/booksscreen.dart';
import 'package:bethelprayerhouse/screens/main_ui/picturespage/pictures.dart';
import 'package:bethelprayerhouse/screens/main_ui/shortspage/shorts.dart';
import 'package:bethelprayerhouse/screens/main_ui/videospage/videos.dart';
import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';

import '../../../custom_widgets/screen_size.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
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
            child: Column(children: [
              const TopSearchWidget(show: true, backarrowshow: true),
              const SizedBox(height: 31),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'Sermons',
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
              for (int i = 0; i < 3; i++)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  width: getWidth(context),
                  decoration: BoxDecoration(
                      image: const DecorationImage(
                          image: AssetImage('assets/doe.png'),
                          fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        TextWidget(
                            text: 'Trusting the Word Of God',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: whiteColor,
                            fontFamily: 'Poppins'),
                        TextWidget(
                            text: 'Pst John Doe',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: whiteColor,
                            fontFamily: 'Poppins'),
                        TextWidget(
                            text: '12-09-2023',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: whiteColor,
                            fontFamily: 'Poppins'),
                        const SizedBox(height: 59),
                        Padding(
                          padding: const EdgeInsets.all(30),
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
                                child: Icon(
                                  Icons.play_arrow,
                                  color: whiteColor,
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'Shorts/Interviews',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                          fontFamily: 'Poppins'),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ShortsScreen()));
                        },
                        child: TextWidget(
                            text: 'View More',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: gradientOne,
                            fontFamily: 'Poppins'),
                      ),
                    ]),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: getWidth(context) / 3,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                            image: AssetImage('assets/shortsimage.png'),
                            fit: BoxFit.cover)),
                    child: Container(
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
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: getWidth(context) / 3,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                            image: AssetImage('assets/shortsimage.png'),
                            fit: BoxFit.cover)),
                    child: Container(
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
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'Pictures',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                          fontFamily: 'Poppins'),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PicturesScreen()));
                        },
                        child: TextWidget(
                            text: 'View More',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: gradientOne,
                            fontFamily: 'Poppins'),
                      ),
                    ]),
              ),
              const SizedBox(height: 18),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 17),
                child: Image.asset('assets/picture1.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 18),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'Books',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                          fontFamily: 'Poppins'),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const BooksScreen()));
                        },
                        child: TextWidget(
                            text: 'View More',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: gradientOne,
                            fontFamily: 'Poppins'),
                      ),
                    ]),
              ),
              const SizedBox(height: 18),
              SizedBox(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < 5; i++)
                        Column(
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 17),
                              child: Image.asset('assets/bookimage3.png',
                                  fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 5),
                            TextWidget(
                                text: "Watchman Nee",
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
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 23),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'Testimonies',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                          fontFamily: 'Poppins'),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const VideoScreen()));
                        },
                        child: TextWidget(
                            text: 'View More',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: gradientOne,
                            fontFamily: 'Poppins'),
                      ),
                    ]),
              ),
              Column(
                children: [
                  const SizedBox(height: 18),
                  Container(
                      width: getWidth(context),
                      margin: const EdgeInsets.symmetric(horizontal: 17),
                      child: Container(
                        decoration: BoxDecoration(
                            image: const DecorationImage(
                                image: AssetImage('assets/videoimage.png'),
                                fit: BoxFit.fill),
                            borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          // child: Center(child: Image.asset('assets/youtube.png'))
                        ),
                      )),
                  const SizedBox(height: 13),
                  SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextWidget(
                            text: "Sunday Worship Service",
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: amberredColor,
                            fontFamily: 'Poppins'),
                        const SizedBox(height: 6),
                        TextWidget(
                            text: "Bethel prayer housee",
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                        const SizedBox(height: 6),
                        TextWidget(
                            text: "Narperville, iL",
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: blackColor,
                            fontFamily: 'Poppins'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: 6,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 10,
                              childAspectRatio: 3 / 2,
                              crossAxisCount: 3),
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          decoration: BoxDecoration(
                              image: const DecorationImage(
                                  image: AssetImage('assets/videoimage.png'),
                                  fit: BoxFit.fill),
                              borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            //child: Center(child: Image.asset('assets/youtube.png'))
                          ),
                        );
                      },
                    ),
                  )
                ],
              )
            ]),
          ),
        ),
      ),
    );
  }
}
