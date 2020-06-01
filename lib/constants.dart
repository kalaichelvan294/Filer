import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

Widget cornorIcon() =>  Align(
                alignment: Alignment.topRight,
                child: Container(
                alignment: Alignment.center,
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Color(0xFFF2BEA1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset("assets/icons/menu.svg"),
              ),
            );
            