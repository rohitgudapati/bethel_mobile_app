import 'package:bethelprayerhouse/screens/main_ui/homepage/home_page.dart';
import 'package:bethelprayerhouse/screens/main_ui/ministriespage/ministries.dart';
import 'package:bethelprayerhouse/screens/main_ui/resourcespage/resourcespage.dart';
import 'package:bethelprayerhouse/screens/main_ui/songspage/songspage.dart';
import 'package:bethelprayerhouse/screens/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BottomPage extends StatefulWidget {
  const BottomPage({super.key});

  @override
  State<BottomPage> createState() => _BottomPageState();
}

class _BottomPageState extends State<BottomPage> {
  List screens = [
    const SongsScreen(),
    const ResourceScreen(),
    const MinistriesScreen(),
     Container(
      color: Colors.lightBlue,
    ),
    const HomeScreen(),
  ];
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens.elementAt(selectedIndex),
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(31))
        ),
        onPressed: () {
          setState(() {
            selectedIndex = 4;
          });
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(

        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        color: whiteColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 2,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: selectedIndex == 0 ? SvgPicture.asset('assets/black_songs.svg') :  SvgPicture.asset('assets/songs.svg')  ,
              onPressed: () {
                setState(() {
                  selectedIndex = 0;
                });
              },
            ),
            IconButton(
              icon: selectedIndex == 1 ? SvgPicture.asset('assets/resorce_black.svg') :  SvgPicture.asset('assets/resorce.svg')  ,
              onPressed: () {
                 setState(() {
                  selectedIndex = 1;
                });
              },
            ),
            IconButton(

              icon:selectedIndex == 2 ? SvgPicture.asset('assets/ministry_black.svg') :  SvgPicture.asset('assets/ministry.svg')  ,
              onPressed: () {
                 setState(() {
                  selectedIndex = 2;
                });
              },
            ),
            IconButton(
              icon: selectedIndex == 3 ? SvgPicture.asset('assets/icon _person_.svg') :  SvgPicture.asset('assets/icon _person_.svg')  ,
              onPressed: () {
                 setState(() {
                  selectedIndex = 3;
                });
              },
            ),
          ],
        ),
      ),
     
    );
  }
}