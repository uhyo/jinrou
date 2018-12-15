import { NowPrize } from '../defs';
import { PrizeStore } from '../store';
import { runInAction } from 'mobx';

/**
 * Whether given selection selects a listed prize.
 */
export function isPrizeSelected(store: PrizeStore, prizeId: string): boolean {
  return (
    store.selection != null &&
    store.selection.type === 'prize' &&
    store.selection.value === prizeId
  );
}
/**
 * Whether given selection selects a conjunction.
 */
export function isConjunctionSelected(
  store: PrizeStore,
  conjunction: string,
): boolean {
  return (
    store.selection != null &&
    store.selection.type === 'conjunction' &&
    store.selection.value === conjunction
  );
}
/**
 * Whether given selection selects a trash.
 */
export function isTrashSelected(store: PrizeStore): boolean {
  return store.selection != null && store.selection.type === 'trash';
}
/**
 * Whether given selection selects a nowprize.
 */
export function isNowprizeSelected(store: PrizeStore, index: number): boolean {
  return (
    store.selection != null &&
    store.selection.type === 'now' &&
    store.selection.index === index
  );
}

/**
 * Check equality of NowPrize.
 */
function nowPrizeEqual(left: NowPrize, right: NowPrize): boolean {
  return left.type === right.type && left.value === right.value;
}

/**
 * Handle a click of existing prize.
 */
export function clickPrizeLogic(store: PrizeStore, prize: NowPrize): void {
  const selection = store.selection;
  runInAction(() => {
    if (selection == null || selection.type === 'trash') {
      store.setSelection(prize);
    } else if (selection.type === 'now') {
      store.updateNowPrize(selection.index, prize);
      store.setSelection(null);
    } else if (!nowPrizeEqual(selection, prize)) {
      store.setSelection(prize);
    } else {
      store.setSelection(null);
    }
  });
}

/**
 * Handle a click of prize template.
 */
export function clickNowPrizeLogic(store: PrizeStore, index: number): void {
  const selection = store.selection;
  runInAction(() => {
    if (selection != null && selection.type === 'trash') {
      store.deleteNowPrize(index);
      store.setSelection(null);
    } else if (selection != null && selection.type !== 'now') {
      store.updateNowPrize(index, selection);
      store.setSelection(null);
    } else if (selection == null || selection.index !== index) {
      store.setSelection({
        type: 'now',
        index,
      });
    } else {
      store.setSelection(null);
    }
  });
}

/**
 * Handle a click of trash.
 */
export function clickTrashLogic(store: PrizeStore): void {
  const selection = store.selection;
  runInAction(() => {
    if (
      selection == null ||
      selection.type === 'prize' ||
      selection.type === 'conjunction'
    ) {
      store.setSelection({ type: 'trash' });
    } else if (selection.type === 'trash') {
      store.setSelection(null);
    } else {
      store.deleteNowPrize(selection.index);
      store.setSelection(null);
    }
  });
}
