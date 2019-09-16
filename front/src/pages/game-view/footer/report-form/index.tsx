import * as React from 'react';
import { useI18n } from '../../../../i18n/react';
import { Button } from '../../../../common/forms/button';
import { FontAwesomeIcon } from '../../../../util/icon';
import { Form, Description } from './elements';
import { ReportFormConfig, ReportFormQuery } from '../../defs';
import {
  Controls,
  ControlsMain,
} from '../../../../common/forms/controls-wrapper';
import { RadioButtons } from '../../../../common/forms/radio';
import { useLocalStore, useObserver } from 'mobx-react-lite';
import { PlainText } from '../../../../common/forms/plain-text';
import { Textarea } from '../../../../common/forms/text';
import { showMessageDialog } from '../../../../dialog';

export const ReportForm: React.FC<{
  open: boolean;
  reportForm: ReportFormConfig;
  onSubmit: (query: ReportFormQuery) => void;
}> = ({ open, reportForm, onSubmit }) => {
  const store = useLocalStore(() => ({
    kindIndex: 0,
    setKind(kindIndex: number) {
      this.kindIndex = kindIndex;
    },
  }));

  const mainFormRef = React.useRef<HTMLFormElement | null>(null);
  const textAreaRef = React.useRef<HTMLTextAreaElement | null>(null);
  React.useEffect(
    () => {
      // if openState changed to true, scroll to the form.
      if (
        open &&
        mainFormRef.current != null &&
        mainFormRef.current.scrollIntoView != null
      ) {
        mainFormRef.current.scrollIntoView({
          behavior: 'smooth',
          block: 'nearest',
        });
      }
    },
    [open],
  );
  const handleKindChange = React.useCallback((kindIndexStr: string) => {
    store.setKind(Number(kindIndexStr));
  }, []);
  const handleSubmit = React.useCallback(
    (e: React.SyntheticEvent<HTMLFormElement>) => {
      e.preventDefault();
      const query: ReportFormQuery = {
        kind: reportForm.categories[store.kindIndex].name,
        content: (textAreaRef.current && textAreaRef.current.value) || '',
      };
      onSubmit(query);
      showMessageDialog({
        modal: true,
        title: t('reportForm.title'),
        message: t('reportForm.thankyou'),
        ok: t('reportForm.close'),
      });
    },
    [],
  );
  const t = useI18n('game_client');
  return useObserver(() => {
    if (t == null) {
      return null;
    }
    if (!reportForm.enable || reportForm.categories.length === 0) {
      return null;
    }
    const selected = reportForm.categories[store.kindIndex];
    return !open ? null : (
      <section>
        <Form ref={mainFormRef} onSubmit={handleSubmit}>
          <h2>{t('reportForm.title')}</h2>
          {t('reportForm.description')
            .split('\n')
            .map((line: string, i: number) => (
              <Description key={i}>{line}</Description>
            ))}
          <Controls title={t('reportForm.kind')}>
            <RadioButtons
              current={String(store.kindIndex)}
              options={reportForm.categories.map((obj, i) => ({
                value: String(i),
                label: obj.name,
                title: obj.description,
              }))}
              onChange={handleKindChange}
            />
            <PlainText>
              <b>{selected.name}</b>: {selected.description}
            </PlainText>
          </Controls>
          <Controls title={t('reportForm.content')}>
            <Textarea
              ref={textAreaRef}
              rows={5}
              maxLength={reportForm.maxLength}
              placeholder={t('reportForm.contentPlaceHolder')}
              required
            />
          </Controls>
          <ControlsMain>
            <Button expand type="submit">
              <FontAwesomeIcon icon={['far', 'paper-plane']} />{' '}
              {t('reportForm.send')}
            </Button>
          </ControlsMain>
        </Form>
      </section>
    );
  });
};
