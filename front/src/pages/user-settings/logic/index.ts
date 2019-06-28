import { UserSettingsStore } from '../store';
import { ColorState } from '../color-profile/color-box';
import { UserSettingDatabase, ColorDocWithoutId, ColorDoc } from './indexeddb';
import { showPromptDialog, showConfirmDialog } from '../../../dialog';
import { deepClone } from '../../../util/deep-clone';
import { runInAction } from 'mobx';
import { startEditUpdator, endEditUpdator } from './tab-updator';
import {
  ColorProfileData,
  defaultColorProfile1,
} from '../../../defs/color-profile';
import { themeStore } from '../../../theme';
import { deepExtend } from '../../../util/deep-extend';
import { ColorName } from '../defs/color-profile';
import { TranslationFunction } from '../../../i18n';

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
  const profiles = (await db.color.toArray()).map(updateProfileToLatest);
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
  const { colorFocus, editing } = tab;
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
  if (currentProfile.id == null || !editing) {
    // this  cannot edited now.
    const ch = await startEditLogic(t, store, currentProfile);
    if (!ch) {
      return;
    }
  }
  // give them focus.
  store.updateTab(tab => ({
    ...tab,
    colorFocus: {
      key: colorName,
      type,
    },
  }));
}

/**
 * Logic when color is changed (realtime).
 */
export function colorChangeLogic(
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
  color: ColorState,
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
  color: ColorState,
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
  // save into store.
  store.updateProfileById(currentId, currentProfile);
  // then, save into the db.
  const db = new UserSettingDatabase();
  await db.transaction('rw', db.color, () =>
    db.color.put({
      ...currentProfile,
      id: currentId,
    }),
  );
  // if this is currently used theme, set into current theme.
  if (themeStore.savedTheme.colorProfile.id === currentId) {
    themeStore.update({
      colorProfile: currentProfile,
    });
    themeStore.saveToStorage();
  }
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
    const addedProfile = await newProfileLogic(t, store, profile);
    if (addedProfile == null) {
      // canceled.
      return false;
    }
    runInAction(() => {
      // then update the store to editing mode.
      store.updateTab(startEditUpdator());
      store.setCurrentProfile(addedProfile);
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
      // fill in case new color is introduced.
      store.setCurrentProfile(updateProfileToLatest(profileData));
      store.updateTab(startEditUpdator());
    });
  }
  return true;
}

function updateProfileToLatest(profileDoc: ColorDoc): ColorProfileData {
  return {
    ...profileDoc,
    profile: deepExtend(defaultColorProfile1.profile, profileDoc.profile),
  };
}

/**
 * Logic to add a profile.
 * Returns new profile if successfully added.
 */
export async function newProfileLogic(
  t: TranslationFunction,
  store: UserSettingsStore,
  base: ColorProfileData = store.currentProfile,
): Promise<ColorProfileData | null> {
  const newName = await showPromptDialog({
    modal: true,
    title: t('color.profileNameDialog.title'),
    message: t('color.profileNameDialog.newMessage'),
    ok: t('color.profileNameDialog.ok'),
    cancel: t('color.profileNameDialog.cancel'),
  });
  if (!newName) {
    // canceled.
    return null;
  }
  // otherwise, new data is made.
  const newProfile: ColorDocWithoutId = {
    name: newName,
    profile: deepClone(base.profile),
  };
  // write to DB.
  const db = new UserSettingDatabase();
  const addedId = await db.transaction('rw', db.color, () =>
    db.color.add(newProfile as any),
  );
  // reload the store.
  await loadProfilesLogic(store);
  const addedProfile = {
    ...newProfile,
    id: addedId,
  };
  // use this one.
  useProfileLogic(store, addedProfile);
  return {
    ...newProfile,
    id: addedId,
  };
}

/**
 * Logic to delete profile./
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
