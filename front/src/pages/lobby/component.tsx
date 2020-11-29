import React, { useCallback, useState } from 'react';
import styled from 'styled-components';
import { Button } from '../../common/forms/button';
import { i18n, I18nProvider } from '../../i18n';
import { FontAwesomeIcon } from '../../util/icon';
import { ReportFormConfig, ReportFormQuery } from '../game-view/defs';
import { ReportForm } from '../game-view/footer/report-form';

interface IPropLobby {
  i18n: i18n;
  reportForm: ReportFormConfig;
  onReportFormSubmit(query: ReportFormQuery): void;
}

export const Lobby: React.FC<IPropLobby> = ({
  i18n,
  reportForm,
  onReportFormSubmit,
}) => {
  const [reportFormOpen, setReportFormOpen] = useState(false);
  const submitHandler = useCallback(
    (query: ReportFormQuery) => {
      setReportFormOpen(false);
      onReportFormSubmit(query);
    },
    [onReportFormSubmit],
  );
  return (
    <I18nProvider i18n={i18n}>
      {reportForm.enable ? (
        <ButtonWrapper>
          <Button onClick={() => setReportFormOpen(state => !state)}>
            <FontAwesomeIcon icon={['far', 'paper-plane']} />{' '}
            {i18n.t('game_client:reportForm.title')}
          </Button>
        </ButtonWrapper>
      ) : null}
      {reportForm.enable ? (
        <ReportForm
          open={reportFormOpen}
          reportForm={reportForm}
          onSubmit={submitHandler}
        />
      ) : null}
    </I18nProvider>
  );
};

const ButtonWrapper = styled.div`
  text-align: right;
`;
