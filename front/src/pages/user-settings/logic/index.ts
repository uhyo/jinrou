import { ColorName } from '../defs';
import { UserSettingsStore } from '../store';
import { ColorResult } from '../color-profile/color-box';
import { UserSettingDatabase, ColorDocWithoutId } from './indexeddb';
import { showPromptDialog, showConfirmDialog } from '../../../dialog';
import { TranslationFunction } from 'i18next';
import { deepClone } from '../../../util/deep-clone';
import { runInAction } from 'mobx';
import { startEditUpdator, endEditUpdator } from './tab-updator';
import { ColorProfileData } from '../../../defs/color-profile';
import { themeStore } from '../../../theme';

/**
 * Reset store's color profile.
 */
export function resetColorProfileLogic(store: UserSettingsStore): void {
  runInAction(() => {
    store.setCurrentProfile(store.defaultProfile);
    store.updateTab(endEditUpdator());
  });
}

/**
 * Logic which loads profiles from db.
 */
export async function loadProfilesLogic(
  store: UserSettingsStore,
): Promise<void> {
  const db = new UserSettingDatabase();
  const profiles = await db.color.toArray();
  // Read current theme.
  const currentProfile = themeStore.savedTheme.colorProfile;
  // check whether current theme is in saved profiles.
  if (profiles.some(p => p.id === currentProfile.id)) {
    runInAction(() => {
      store.updateSavedProfiles(profiles);
      store.setCurrentProfile(currentProfile);
    });
    return;
  }
  // if not the default one, discard its id.
  runInAction(() => {
    store.updateSavedProfiles(profiles);
    store.setCurrentProfile({
      ...currentProfile,
      id: null,
      name: currentProfile.name || '?',
    });
  });
}
/**
 * Logic when focus is requested.
 */
export async function requestFocusLogic(
  t: TranslationFunction,
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
): Promise<void> {
  const { tab, currentProfile } = store;
  if (tab.page !== 'color') {
    return;
  }
  const { colorFocus } = tab;
  if (
    colorFocus != null &&
    colorFocus.key === colorName &&
    colorFocus.type === type
  ) {
    // it has already focus.
    store.setTab({
      ...tab,
      colorFocus: null,
    });
    return;
  }
  if (currentProfile.id == null) {
    // this is default one; cannot edited.
    const ch = await startEditLogic(t, store, currentProfile);
    if (!ch) {
      return;
    }
  }
  // give them focus.
  store.setTab({
    ...tab,
    colorFocus: {
      key: colorName,
      type,
    },
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
export async function colorChangeCompleteLogic(
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
  color: ColorResult,
): Promise<void> {
  // update profile with current data.
  colorChangeLogic(store, colorName, type, color);
  const { currentProfile, tab } = store;
  if (currentProfile.id == null) {
    // this cannot be saved!?
    throw new Error('Cannot update default profile');
  }
  if (tab.page !== 'color' || !tab.editing) {
    throw new Error('Cannot update profile when not editing');
  }
  const currentId = currentProfile.id;
  // then, save into the db.
  const db = new UserSettingDatabase();
  await db.transaction('rw', db.color, () =>
    db.color.put({
      ...currentProfile,
      id: currentId,
    }),
  );
}

/**
 * Logic to start editing a profile.
 * Returns Promise which resolves to true if starting is successful.
 */
export async function startEditLogic(
  t: TranslationFunction,
  store: UserSettingsStore,
  profile: ColorProfileData,
): Promise<boolean> {
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
      return false;
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
      store.updateTab(startEditUpdator());
      store.setCurrentProfile({
        id: addedId,
        ...newProfile,
      });
    });
  } else {
    const profileId = profile.id;
    // Read from database this setting.
    const db = new UserSettingDatabase();
    const profileData = await db.color.get(profileId);
    if (profileData == null) {
      // This was already deleted.
      resetColorProfileLogic(store);
      // Trigger reload.
      await loadProfilesLogic(store);
      return false;
    }
    // profileData was loaded.
    runInAction(() => {
      store.setCurrentProfile(profileData);
      store.updateTab(startEditUpdator());
    });
  }
  return true;
}

/**
 * Logic to delete profile.
 */
export async function deleteProfileLogic(
  t: TranslationFunction,
  store: UserSettingsStore,
  profile: ColorProfileData,
): Promise<void> {
  const profileId = profile.id;
  if (profileId == null) {
    throw new Error('Cannot delete default profile');
  }
  // prompt user.
  const res = await showConfirmDialog({
    modal: true,
    title: t('color.deleteProfileDialog.title'),
    message: t('color.deleteProfileDialog.message', { name: profile.name }),
    yes: t('color.deleteProfileDialog.ok'),
    no: t('color.deleteProfileDialog.cancel'),
  });
  if (!res) {
    // if user canceled, return.
    return;
  }
  // if current profile became invalid, reset.
  if (store.currentProfile.id === profileId) {
    resetColorProfileLogic(store);
  }

  const db = new UserSettingDatabase();
  await db.transaction('rw', db.color, () => db.color.delete(profileId));
  // reload profiles.
  await loadProfilesLogic(store);
}

/**
 * Use a selected profile.
 */
export function useProfileLogic(
  store: UserSettingsStore,
  profile: ColorProfileData,
) {
  // focus in store.
  runInAction(() => {
    store.setCurrentProfile(profile);
    store.updateTab(endEditUpdator());
  });
  // set current theme.
  themeStore.update({
    colorProfile: profile,
  });
  themeStore.saveToStorage();
}
