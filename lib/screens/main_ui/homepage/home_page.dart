import 'package:bethelprayerhouse/custom_widgets/screen_size.dart';
import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../custom_widgets/text_widget.dart';
import '../../../custom_widgets/top_givenow_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List images = [
    "assets/verse1.png",
    "assets/verse2.png",
    "assets/verse3.png",
    "assets/verse1.png",
    "assets/verse2.png"
  ];
  List names = [
    "Sunday Prayer",
    "Monday Prayer",
    "Worship Prayer",
    "Good Friday Prayer",
    "God Prayer"
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: getHeight(context),
        width: getWidth(context),
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/bg.png'), fit: BoxFit.cover)),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
               const TopGiveNowWidget(),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 23),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                              text: 'Hi katerin ,',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: greyTextColor,
                              fontFamily: "Poppins"),
                          TextWidget(
                              text: 'Good Morning !',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: blackColor,
                              fontFamily: 'Poppins'),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: whiteColor),
                        child: Icon(
                          Icons.notifications,
                          color: blackColor,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 23),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                          text: 'Daily Refresh',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                          fontFamily: 'Poppins'),
                      SizedBox(
                        child: Row(
                          children: [
                            TextWidget(
                                text: 'Today',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: blackColor,
                                fontFamily: "Poppins"),
                            TextWidget(
                                text: '/',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: blackColor,
                                fontFamily: "Poppins"),
                            TextWidget(
                                text: 'All',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: greyTextColor,
                                fontFamily: "Poppins")
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: getWidth(context),
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/church.jpg'),
                          fit: BoxFit.fill),
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 18, top: 16),
                        child: TextWidget(
                            text: 'verse of the day',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: whiteColor,
                            fontFamily: 'Poppins'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 18, top: 10),
                        child: TextWidget(
                            text: 'Mark 16:15 NIV',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: whiteColor,
                            fontFamily: 'Poppins'),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        child: TextWidget(
                          text:
                              'He said to them, “Go into all the world and preach the gospel to all creation.”',
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: whiteColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                SvgPicture.asset('assets/heart_white.svg'),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextWidget(
                                    text: '424.1k',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: whiteColor,
                                    fontFamily: 'Poppins')
                              ],
                            ),
                            Column(
                              children: [
                                SvgPicture.asset('assets/share_white.svg'),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextWidget(
                                    text: '21.7k',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: whiteColor,
                                    fontFamily: 'Poppins')
                              ],
                            ),
                            Column(
                              children: [
                                SvgPicture.asset('assets/more_white_icons.svg'),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextWidget(
                                    text: 'More',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: whiteColor,
                                    fontFamily: 'Poppins')
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50))),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                                text: 'Verse of the day images',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                                fontFamily: "Poppins"),
                            TextWidget(
                                text: 'View More',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: gradientOne,
                                fontFamily: "Poppins")
                          ],
                        ),
                      ),
                      SizedBox(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                              ),
                              for (int i = 0; i < images.length; i++)
                                Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(images[i])),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10))),
                                )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                                text: 'Live Streaming',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                                fontFamily: "Poppins"),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: const BoxDecoration(
                          image: DecorationImage(image: AssetImage('assets/live_event.jpeg'),fit: BoxFit.fill),
                          borderRadius: BorderRadius.all(Radius.circular(20))
                        ),
                        child: SizedBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 25,
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      child: Row(
                                        children: [
                                          SvgPicture.asset('assets/white_eye.svg'),
                                          const SizedBox(
                                            width: 07,
                                          ),
                                          TextWidget(text: '1.72k', fontSize: 12, fontWeight: FontWeight.w400, color: whiteColor, fontFamily: 'Poppins')
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 08,vertical: 04),
                                      decoration: BoxDecoration(
                                        color: redColor,
                                        borderRadius: const BorderRadius.all(Radius.circular(20 ))
                                      ),
                                      child: Row(
                                        children: [
                                         Container(
                                          height: 09,
                                          width: 09,
                                          decoration: BoxDecoration(
                                            color: whiteColor,
                                            shape: BoxShape.circle
                                          ),
                                         ),
                                          const SizedBox(
                                            width: 07,
                                          ),
                                          TextWidget(text: 'Live', fontSize: 12, fontWeight: FontWeight.w600, color: whiteColor, fontFamily: 'Poppins')
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 150,
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 20,top: 50),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(text: 'God\'s Love', fontSize: 35, fontWeight: FontWeight.w600, color: whiteColor, fontFamily: 'Poppins'),
                                    TextWidget(text: 'Bethel Prayer House', fontSize: 12, fontWeight: FontWeight.w400, color: greyTextColor, fontFamily: 'Poppins'),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                              ),
                              for(int i=0;i<images.length;i++)
                              Container(
                                margin: const EdgeInsets.only(right: 20),
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  image: DecorationImage(image: AssetImage(images[i])),
                                  shape: BoxShape.circle,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                                text: 'Events',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                                fontFamily: "Poppins"),
                            TextWidget(
                                text: 'View More',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: gradientOne,
                                fontFamily: "Poppins")
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                       decoration: const BoxDecoration(
                        image: DecorationImage(image: AssetImage('assets/live_event.jpeg'),fit: BoxFit.fill),
                        borderRadius: BorderRadius.all(Radius.circular(20))
                       ),
                       child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(text: 'Date: March 12, 2024', fontSize: 08, fontWeight: FontWeight.w400, color: whiteColor, fontFamily: 'Poppins'),
                             TextWidget(text: 'Time: 12:00 PM', fontSize: 08, fontWeight: FontWeight.w400, color: whiteColor, fontFamily: 'Poppins')
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                        Container(
                          margin: const EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(text: 'Good Friday', fontSize: 35, fontWeight: FontWeight.w500, color: whiteColor, fontFamily: 'Poppins'),
                               TextWidget(text: 'Bethel Prayer House', fontSize: 10, fontWeight: FontWeight.w400, color: whiteColor, fontFamily: 'Poppins'),
                                TextWidget(text: 'Venue: 456 Park Avenue, New york', fontSize: 08, fontWeight: FontWeight.w400, color: whiteColor, fontFamily: 'Poppins'),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        )
                        ],
                       ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                                text: 'Services',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                                fontFamily: "Poppins"),
                            TextWidget(
                                text: 'View More',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: gradientOne,
                                fontFamily: "Poppins")
                          ],
                        ),
                      ),
                      SizedBox(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                              ),
                              for (int i = 0; i < images.length; i++)
                                SizedBox(
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 10),
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage(images[i])),
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(10))),
                                      ),
                                      const SizedBox(
                                        height: 03,
                                      ),
                                      TextWidget(text: names[i], fontSize: 10, fontWeight: FontWeight.w600, color: blackColor, fontFamily: 'Poppins')
                                    ],
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                                text: 'Prayer Request',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                                fontFamily: "Poppins"),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 23
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: blackColor),
                          borderRadius: const BorderRadius.all(Radius.circular(20))
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20,top: 20),
                              child: Row(
                                children: [
                                  TextWidget(text: 'Name', fontSize: 12, fontWeight: FontWeight.w600, color: blackColor, fontFamily: 'Poppins'),
                                  TextWidget(text: '*', fontSize: 10, fontWeight: FontWeight.w600, color: redColor, fontFamily: 'Poppins'),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              height: 30,
                              child: TextFormField(
                                
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: greyTextColor,
                                  border:  OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 20,top: 20),
                              child: Row(
                                children: [
                                  TextWidget(text: 'Email', fontSize: 12, fontWeight: FontWeight.w600, color: blackColor, fontFamily: 'Poppins'),
                                  TextWidget(text: '*', fontSize: 10, fontWeight: FontWeight.w600, color: redColor, fontFamily: 'Poppins'),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              height: 30,
                              child: TextFormField(
                                
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: greyTextColor,
                                  border:  OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 20,top: 20),
                              child: Row(
                                children: [
                                  TextWidget(text: 'Phone', fontSize: 12, fontWeight: FontWeight.w600, color: blackColor, fontFamily: 'Poppins'),
                                  TextWidget(text: '*', fontSize: 10, fontWeight: FontWeight.w600, color: redColor, fontFamily: 'Poppins'),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              height: 30,
                              child: TextFormField(
                                
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: greyTextColor,
                                  border:  OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(0))
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 20,top: 20),
                              child: Row(
                                children: [
                                  TextWidget(text: 'Prayer Request', fontSize: 12, fontWeight: FontWeight.w600, color: blackColor, fontFamily: 'Poppins'),
                                  TextWidget(text: '*', fontSize: 10, fontWeight: FontWeight.w600, color: redColor, fontFamily: 'Poppins'),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                             
                              child: TextFormField(
                                maxLines: 6,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: greyTextColor,
                                  border:  OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(03))
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(03))
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greyTextColor),
                                    borderRadius: const BorderRadius.all(Radius.circular(03))
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                                text: 'Church Address',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                                fontFamily: "Poppins"),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        decoration:  BoxDecoration(
                          color: whiteColor,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 3,
                              color: greyTextColor,
                              spreadRadius: 3
                            )
                          ],
                          image: const DecorationImage(image: AssetImage('assets/map.jpeg'),fit: BoxFit.fill),
                          borderRadius: const BorderRadius.all(Radius.circular(20))
                        ),
                        child: SizedBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 25,
                              ),
                              Container(
                                height: 100,
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                       Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           TextWidget(text: '756 South River Rd, Naperville', fontSize: 12, fontWeight: FontWeight.w500, color: whiteColor, fontFamily: 'Poppins'),
                                            TextWidget(text: 'United States', fontSize: 08, fontWeight: FontWeight.w400, color: whiteColor, fontFamily: 'Poppins'),
                                           const SizedBox(
                                            height: 10,
                                           )
                                         ],
                                       ),
                                       Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 05,vertical:03),
                                        decoration: BoxDecoration(
                                          color: whiteColor,
                                          borderRadius: const BorderRadius.all(Radius.circular(05))
                                        ),
                                        child: TextWidget(text: 'View on Map', fontSize: 10, fontWeight: FontWeight.w500, color: gradientOne, fontFamily: 'Poppins'),
                                       )                                        
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                    ]))),
                      const SizedBox(
                        height: 25,
                      )
              ],
            ),
          ),
       ] )))
      ),
    );
  }
}

