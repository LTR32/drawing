import 'package:drawing_app/l10n/l10n.dart';
import 'package:drawing_app/provider/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguageWidget extends StatelessWidget {
  const LanguageWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final flag = L10n.getFlag(locale.languageCode);

    return Center(
      child: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 72,
        child: Text(
          flag,
          style: TextStyle(fontSize: 80)
        ),
      ),
    );
  }
}

class LanguagePickerWidget extends StatelessWidget {
  const LanguagePickerWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaLeProvider>(context);
    final locale = provider.locale;

    return DropdownButtonHideUnderline(
        child: DropdownButton(
          value: locale,
          hint: Container(
            margin: EdgeInsets.only(left: 13),
            child: Image.asset('assets/icones/drapeau_fra_ang.png', height: 25, fit: BoxFit.cover,),
          ),
          icon: Container(width: 12,),
          items: L10n.all
            .map(
                  (locale) {
                    final flag = L10n.getFlag(locale.languageCode);

                    return DropdownMenuItem(
                      child: Center(
                          child: Text(
                            flag,
                            style: TextStyle(fontSize: 32),
                          )
                      ),
                      value: locale,
                      onTap: () {
                        final provider = 
                            Provider.of<LocaLeProvider>(context,listen: false );
                        provider.setLocale(locale);
                      },
                    );
                  },
          )
            .toList(),
          onChanged: (_) {},
        )
    );
  }
}

