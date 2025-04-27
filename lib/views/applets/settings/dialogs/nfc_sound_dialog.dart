import 'package:canokey_console/generated/l10n.dart';
import 'package:canokey_console/helper/storage/local_storage.dart';
import 'package:canokey_console/helper/utils/audio.dart';
import 'package:canokey_console/helper/utils/ui_mixins.dart';
import 'package:canokey_console/helper/widgets/customized_button.dart';
import 'package:canokey_console/helper/widgets/customized_text.dart';
import 'package:canokey_console/helper/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NfcSoundDialog extends StatelessWidget with UIMixin {
  const NfcSoundDialog({super.key});

  static Future<void> show() {
    return Get.dialog(const NfcSoundDialog());
  }

  Widget _buildNfcSoundItem(BuildContext context, RxInt nfcSound, int sound) {
    final title = sound == -1 ? S.of(context).disableSound : "${S.of(context).nfcSound} ${sound + 1}";
    return RadioListTile(
      dense: true,
      contentPadding: Spacing.x(16),
      title: CustomizedText.bodyMedium(title),
      value: sound,
      groupValue: nfcSound.value,
      activeColor: contentTheme.primary,
      onChanged: (value) => nfcSound.value = value!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nfcSound = (LocalStorage.getNfcSound() ?? Audio.AUDIO_SET_DEFAULT).obs;

    return Dialog(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: Spacing.all(16),
              child: CustomizedText.labelLarge(S.of(context).nfcSound),
            ),
            Divider(height: 0, thickness: 1),
            Obx(() => Column(
                    children: List.generate(Audio.AUDIO_SET_NUM + 1, (set) {
                  // generate 0, 1, 2, .., n-1, n
                  if (set == Audio.AUDIO_SET_NUM) set = -1;
                  return _buildNfcSoundItem(context, nfcSound, set);
                }, growable: false))),
            Divider(height: 0, thickness: 1),
            Padding(
              padding: Spacing.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomizedButton.rounded(
                    onPressed: () => Navigator.pop(context),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).cancel, color: contentTheme.onSecondary),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () => Audio.playAll(nfcSound.value),
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.secondary,
                    child: CustomizedText.labelMedium(S.of(context).play, color: contentTheme.onPrimary),
                  ),
                  Spacing.width(16),
                  CustomizedButton.rounded(
                    onPressed: () {
                      LocalStorage.setNfcSound(nfcSound.value);
                      Audio.reloadSoundSet();
                      Navigator.pop(context);
                    },
                    elevation: 0,
                    padding: Spacing.xy(20, 16),
                    backgroundColor: contentTheme.primary,
                    child: CustomizedText.labelMedium(S.of(context).confirm, color: contentTheme.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
