import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';


Widget greenIntroWidget(){
  return Container(
    width: Get.width,
    decoration: const BoxDecoration(
      image: DecorationImage(
        image:AssetImage("assets/mask.png"),
        fit: BoxFit.cover
      )

    ),
    height: Get.height*0.6,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset("assets/bus icon.svg"),

        const SizedBox(height: 10,),
        // SvgPicture.asset("assets/greenTaxi.svg"),

        Text("BUS FARE",
        style: GoogleFonts.poppins(
        fontSize: 60,
        fontWeight: FontWeight.bold,
        color: Colors.white,
  ),)

       

        

      ],
    ),
  );

}