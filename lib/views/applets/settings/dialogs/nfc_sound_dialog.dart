import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/widgets/app_dialog.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/audio.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NfcSoundDialog extends StatefulWidget {
  const NfcSoundDialog({super.key});

  static Future<void> show() {
    return AppDialog.show(const NfcSoundDialog());
  }

  @override
  State<NfcSoundDialog> createState() => _NfcSoundDialogState();
}

class _NfcSoundDialogState extends State<NfcSoundDialog> with UIMixin {
  late final nfcSound =
      (LocalStorage.getNfcSound() ?? Audio.defaultSoundSet).obs;

  Widget _buildNfcSoundItem(BuildContext context, RxInt nfcSound, int sound) {
    final title = sound == -1
        ? S.of(context).disableSound
        : "${S.of(context).nfcSound} ${sound + 1}";
    return AppDialogChoice(
      title: title,
      selected: nfcSound.value == sound,
      onTap: () => nfcSound.value = sound,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogSurface(
      child: SizedBox(
        width: AppDialogWidth.compact,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDialogHeader(
                title: S.of(context).nfcSound,
                icon: Icons.volume_up_outlined,
              ),
              Divider(height: 0, thickness: 1),
              Obx(
                () => Column(
                  children: List.generate(Audio.soundSetCount + 1, (set) {
                    // generate 0, 1, 2, .., n-1, n
                    if (set == Audio.soundSetCount) set = -1;
                    return _buildNfcSoundItem(context, nfcSound, set);
                  }, growable: false),
                ),
              ),
              Divider(height: 0, thickness: 1),
              AppDialogActions(
                children: [
                  AppDialogAction(
                    label: S.of(context).cancel,
                    onPressed: () => Navigator.pop(context),
                    secondary: true,
                    destructive: false,
                  ),
                  AppDialogAction(
                    label: S.of(context).play,
                    onPressed: () => Audio.playAll(nfcSound.value),
                    secondary: true,
                    destructive: false,
                  ),
                  AppDialogAction(
                    label: S.of(context).confirm,
                    onPressed: () {
                      LocalStorage.setNfcSound(nfcSound.value);
                      Audio.reloadSoundSet();
                      Navigator.pop(context);
                    },
                    secondary: false,
                    destructive: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
