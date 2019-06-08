import * as React from 'react';
import { i18n, I18nProvider } from '../../i18n';
import { Wrapper } from './elements';
import {
  Controls,
  ControlsWrapper,
  ControlsName,
  ControlsDescription,
  ControlsHeader,
  ControlsMain,
  InlineControl,
} from '../../common/forms/controls-wrapper';
import { Input } from '../../common/forms/text';
import { RadioButtons } from '../../common/forms/radio';
import { useI18n } from '../../i18n/react';
import { NewRoomStore } from './store';
import { observer } from 'mobx-react-lite';
import { FontAwesomeIcon } from '../../util/icon';
import { WideButton } from '../../common/button';
import { CheckButton } from '../../common/forms/check-button';
import { Select } from '../../common/forms/select';
import { showConfirmDialog } from '../../dialog';

export interface ThemeDoc {
  /**
   * displayed name of theme.
   */
  name: string;
  /**
   * ID of theme.
   */
  value: string;
}

export interface IPropNewRoom {
  themes: ThemeDoc[];
  store: NewRoomStore;
  onCreate(query: unknown): void;
}

export const NewRoom: React.FunctionComponent<IPropNewRoom> = observer(
  ({ themes, store, onCreate }) => {
    const t = useI18n('newroom_client');
    const nameInputRef = React.useRef<HTMLInputElement | null>(null);
    const passwordInputRef = React.useRef<HTMLInputElement | null>(null);
    const commentInputRef = React.useRef<HTMLInputElement | null>(null);
    const maxNumberInputRef = React.useRef<HTMLInputElement | null>(null);
    const themeSelectRef = React.useRef<HTMLSelectElement | null>(null);
    // memory of whether submit button was explicitly clicked (or pressed).
    const enterPressedRef = React.useRef(false);

    React.useEffect(() => {
      // initialize store with saved jobs.
      if (localStorage.savedRule) {
        try {
          const savedRule = JSON.parse(localStorage.savedRule);
          if ('number' === typeof savedRule.maxnumber) {
            if (maxNumberInputRef.current != null) {
              maxNumberInputRef.current.value = String(savedRule.maxnumber);
            }
          }
          if ('string' === typeof savedRule.blind) {
            store.setBlind(savedRule.blind);
          }
          if ('boolean' === typeof savedRule.gm) {
            store.setGm(savedRule.gm);
          }
          if ('boolean' === typeof savedRule.watchspeak) {
            store.setWatchSpeak(savedRule.watchspeak);
          }
        } catch (e) {
          console.error(e);
        }
      }
    }, []);
    const passwordOptions = React.useMemo(
      () => [
        {
          value: 'no',
          label: t('password.no'),
        },
        {
          value: 'yes',
          label: t('password.yes'),
        },
      ],
      [t],
    );
    const blindOptions = React.useMemo(
      () => [
        {
          value: '',
          label: t('blind.no'),
        },
        {
          value: 'yes',
          label: t('game_client:roominfo.blind'),
        },
        {
          value: 'complete',
          label: t('game_client:roominfo.blindComplete'),
        },
      ],
      [t],
    );
    const gmOptions = React.useMemo(
      () => [
        {
          value: 'no',
          label: t('gm.no'),
        },
        {
          value: 'yes',
          label: t('gm.yes'),
        },
      ],
      [t],
    );
    const watchSpeakOptions = React.useMemo(
      () => [
        {
          value: 'no',
          label: t('watchSpeak.no'),
        },
        {
          value: 'yes',
          label: t('watchSpeak.yes'),
        },
      ],
      [t],
    );
    const keydownHandler = (e: React.KeyboardEvent<HTMLFormElement>) => {
      const target = e.target as HTMLInputElement;
      if (e.key !== 'Enter') {
        return;
      }
      if (target.tagName === 'INPUT' && target.type === 'submit') {
        // allow because user explicitly pressed the submit button.
        enterPressedRef.current = false;
      } else {
        enterPressedRef.current = true;
      }
    };
    const submitHandler = (e: React.SyntheticEvent<HTMLFormElement>) => {
      e.preventDefault();
      const confirmed = !enterPressedRef.current
        ? Promise.resolve(true)
        : showConfirmDialog({
            title: t('title'),
            message: t('confirm.message'),
            yes: t('confirm.yes'),
            no: t('confirm.no'),
          });
      enterPressedRef.current = false;

      confirmed.then(c => {
        if (!c) {
          // canceled by used
          return;
        }

        const getValue = (
          ref: React.RefObject<HTMLInputElement | HTMLSelectElement | null>,
        ) => {
          return ref.current != null ? ref.current.value : '';
        };
        const query = {
          name: getValue(nameInputRef),
          usepassword: store.usePassword ? 'on' : '',
          password: store.usePassword ? getValue(passwordInputRef) : void 0,
          comment: getValue(commentInputRef),
          number: getValue(maxNumberInputRef),
          blind: store.blind,
          theme: getValue(themeSelectRef),
          ownerGM: store.gm ? 'yes' : '',
          watchspeak: store.watchSpeak ? 'on' : 'off',
        };
        onCreate(query);
      });
    };
    return (
      <Wrapper>
        <h1>
          {t('title')}
          {'　'}
          <InlineControl>
            <CheckButton
              slim
              checked={store.descriptionShown}
              onChange={value => store.setDescriptionShown(value)}
            >
              {t('showDescriptionButton')}
            </CheckButton>
          </InlineControl>
        </h1>
        <form onSubmit={submitHandler} onKeyDown={keydownHandler}>
          <ControlsWrapper>
            {/* title input */}
            <ControlsHeader>
              <ControlsName>{t('roomname.title')}</ControlsName>
            </ControlsHeader>
            <ControlsMain>
              <Input type="text" required name="room-name" ref={nameInputRef} />
            </ControlsMain>
            {/* password settings */}
            <ControlsHeader>
              <ControlsName>{t('password.title')}</ControlsName>
              {store.descriptionShown ? (
                <ControlsDescription>
                  {t('password.description')}
                </ControlsDescription>
              ) : null}
            </ControlsHeader>
            <ControlsMain>
              <RadioButtons
                onChange={value => store.setUsePassword(value === 'yes')}
                current={store.usePassword ? 'yes' : 'no'}
                options={passwordOptions}
              />
              {!store.usePassword ? null : (
                <>
                  <FontAwesomeIcon icon="lock" />{' '}
                  <Input
                    type="text"
                    required
                    size={30}
                    placeholder={t('password.placeholder')}
                    ref={passwordInputRef}
                  />
                </>
              )}
            </ControlsMain>
            {/* comment input */}
            <ControlsHeader>
              <ControlsName>{t('comment.title')}</ControlsName>
              {store.descriptionShown ? (
                <ControlsDescription>
                  {t('comment.description')}
                </ControlsDescription>
              ) : null}
            </ControlsHeader>
            <ControlsMain>
              <Input type="text" name="room-comment" ref={commentInputRef} />
            </ControlsMain>
          </ControlsWrapper>
          {/* max number of room. */}
          <Controls
            title={t('maxnumber.title')}
            description={
              store.descriptionShown ? t('maxnumber.description') : void 0
            }
            compact={!store.descriptionShown}
          >
            <Input
              type="number"
              size={10}
              defaultValue="30"
              min="5"
              ref={maxNumberInputRef}
            />
          </Controls>
          {/* blind mode */}
          <Controls
            title={t('blind.title')}
            description={
              store.descriptionShown ? t('blind.description') : void 0
            }
            compact={!store.descriptionShown}
          >
            <RadioButtons
              onChange={value => store.setBlind(value as any)}
              current={store.blind}
              options={blindOptions}
            />
          </Controls>
          {/* theme */}
          {themes.length > 0 ? (
            <Controls
              title={t('theme.title')}
              description={
                store.descriptionShown ? t('theme.description') : void 0
              }
              compact={!store.descriptionShown}
            >
              <Select ref={themeSelectRef}>
                <option value="">{t('theme.none')}</option>
                {themes.map(theme => (
                  <option key={theme.value} value={theme.value}>
                    {theme.name}
                  </option>
                ))}
              </Select>
            </Controls>
          ) : null}
          {/* gm */}
          <Controls
            title={t('gm.title')}
            description={store.descriptionShown ? t('gm.description') : void 0}
            compact={!store.descriptionShown}
          >
            <RadioButtons
              onChange={value => store.setGm(value === 'yes')}
              current={store.gm ? 'yes' : 'no'}
              options={gmOptions}
            />
          </Controls>
          {/* watchSpeak */}
          <Controls
            title={t('watchSpeak.title')}
            description={
              store.descriptionShown ? t('watchSpeak.description') : void 0
            }
            compact={!store.descriptionShown}
          >
            <RadioButtons
              onChange={value => store.setWatchSpeak(value === 'yes')}
              current={store.watchSpeak ? 'yes' : 'no'}
              options={watchSpeakOptions}
            />
          </Controls>
          <WideButton type="submit" disabled={store.formDisabled}>
            {t('create')}
          </WideButton>
        </form>
      </Wrapper>
    );
  },
);
