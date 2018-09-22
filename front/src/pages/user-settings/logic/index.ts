import { ColorName, ColorProfileData } from '../defs';
import { UserSettingsStore } from '../store';
import { ColorResult } from '../color-profile/color-box';
import { UserSettingDatabase, ColorDocWithoutId } from './indexeddb';
import { showPromptDialog } from '../../../dialog';
import { TranslationFunction } from 'i18next';
import { deepClone } from '../../../util/deep-clone';
import { runInAction } from 'mobx';

/**
 * Logic which loads profiles from db.
 */
export function loadProfilesLogic(store: UserSettingsStore): Promise<void> {
  const db = new UserSettingDatabase();
  return db
    .transaction('r', db.color, () => db.color.toArray())
    .then(profiles => {
      store.updateSavedProfiles(profiles);
    })
    .catch(console.error);
}
/**
 * Logic when focus is requested.
 */
export function requestFocusLogic(
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
): void {
  store.updateTab(tab => {
    if (tab.page === 'color') {
      if (
        tab.colorFocus != null &&
        tab.colorFocus.key === colorName &&
        tab.colorFocus.type === type
      ) {
        // it has already focus.
        return {
          ...tab,
          colorFocus: null,
        };
      } else {
        // give them focus.
        return {
          ...tab,
          colorFocus: {
            key: colorName,
            type,
          },
        };
      }
    } else {
      // do not change.
      return tab;
    }
  });
}

/**
 * Logic when color is changed (realtime).
 */
export function colorChangeLogic(
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
  color: ColorResult,
): void {
  store.updateCurrentColor(colorName, type, color.hex);
}

/**
 * Logic run when color is decided.
 */
export function colorChangeCompleteLogic(
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
  color: ColorResult,
): void {
  // TODO
}

/**
 * Logic to start editing a profile.
 */
export async function startEditLogic(
  t: TranslationFunction,
  store: UserSettingsStore,
  profile: ColorProfileData,
) {
  // if profileId is null, this is a default one.
  if (profile.id == null) {
    const newName = await showPromptDialog({
      modal: true,
      title: t('color.profileNameDialog.title'),
      message: t('color.profileNameDialog.newMessage'),
      ok: t('color.profileNameDialog.ok'),
      cancel: t('color.profileNameDialog.cancel'),
    });
    if (!newName) {
      // canceled.
      return;
    }
    // otherwise, new data is made.
    const newProfile: ColorDocWithoutId = {
      name: newName,
      profile: deepClone(profile.profile),
    };
    // write to DB.
    const db = new UserSettingDatabase();
    const addedId = await db.transaction('rw', db.color, () =>
      db.color.add(newProfile as any),
    );
    // reload the store.
    await loadProfilesLogic(store);
    // then update the store to editing mode.
    runInAction(() => {
      store.updateTab(tab => {
        if (tab.page === 'color') {
          return {
            ...tab,
            editing: true,
          };
        } else {
          return tab;
        }
      });
      store.setCurrentProfile({
        id: addedId,
        ...newProfile,
      });
    });
  }
}
