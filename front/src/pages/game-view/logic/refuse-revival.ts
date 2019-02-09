import { i18n } from '../../../i18n';
import {
  showConfirmDialog,
  showMessageDialog,
  showErrorDialog,
} from '../../../dialog';

/**
 * Make a logic to handle refuse revival button.
 */
export function makeRefuseRevivalLogic(
  i18n: i18n,
  refuseRevival: () => Promise<void>,
): () => Promise<void> {
  // Ask whether you really want to refuse revival.
  return async () => {
    const res = await showConfirmDialog({
      modal: true,
      title: i18n.t('game_client:refuseRevival.title') as string,
      message: i18n.t('game_client:refuseRevival.confirm'),
      yes: i18n.t('game_client:refuseRevival.yes'),
      no: i18n.t('game_client:refuseRevival.no'),
    });
    if (!res) {
      return;
    }
    try {
      await refuseRevival();
      // 蘇生辞退結果を表示
      await showMessageDialog({
        title: i18n.t('game_client:refuseRevival.title') as string,
        message: i18n.t('game_client:refuseRevival.result'),
        modal: false,
        ok: i18n.t('game_client:refuseRevival.yes'),
      });
    } catch (e) {
      // エラー
      await showErrorDialog({
        modal: true,
        message: String(e),
      });
    }
  };
}
