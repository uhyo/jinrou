import { Phase } from './defs';

export const phases: Partial<Record<number, Phase>> = {
  0: {
    async step(driver) {
      await driver.messageDialog({
        message: driver.t('phase0.stepMessage'),
      });
    },
  },
};
