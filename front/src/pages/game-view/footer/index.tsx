import { ReportForm } from './report-form';
import React, { useState, useCallback } from 'react';
import { ReportFormConfig, ReportFormQuery, ShareButtonConfig } from '../defs';
import { observer } from 'mobx-react-lite';
import { Button } from '../../../common/forms/button';
import { FontAwesomeIcon } from '../../../util/icon';
import { useI18n } from '../../../i18n/react';
import styled from '../../../util/styled';
import { ShareButton } from './share-button';

interface GameFooterProps {
  reportForm: ReportFormConfig;
  shareButton: ShareButtonConfig;
  onSubmit: (query: ReportFormQuery) => void;
}

export const GameFooter: React.FunctionComponent<GameFooterProps> = observer(
  ({ reportForm, shareButton, onSubmit }) => {
    const t = useI18n('game_client');
    const [reportFormOpen, setReportFormOpen] = useState(false);
    const submitHandler = useCallback(
      (query: ReportFormQuery) => {
        setReportFormOpen(false);
        onSubmit(query);
      },
      [onSubmit],
    );

    return (
      <>
        <ButtonContainer>
          <ShareButton shareButton={shareButton} />
          <Button onClick={() => setReportFormOpen(state => !state)}>
            <FontAwesomeIcon icon={['far', 'paper-plane']} />{' '}
            {t('reportForm.title')}
          </Button>
        </ButtonContainer>
        <ReportForm
          open={reportFormOpen}
          reportForm={reportForm}
          onSubmit={submitHandler}
        />
      </>
    );
  },
);

/**
 * Wrapper of the footer buttons.
 */
const ButtonContainer = styled.div`
  text-align: right;
`;
