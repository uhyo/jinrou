import { showMessageDialog } from '../../../dialog';
import { i18n, TranslationFunction } from '../../../i18n';
import { Driver, DriverMessageDialog } from './defs';

export class InteractiveDriver implements Driver {
  constructor(public t: TranslationFunction) {}
  messageDialog(d: DriverMessageDialog) {
    return showMessageDialog({
      modal: true,
      title: this.t('common.messageDialog.title') as string,
      ok: this.t('common.messageDialog.ok'),
      ...d,
    });
  }
}
