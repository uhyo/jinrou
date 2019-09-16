import { ReportForm } from '../report-form';
import React from 'react';
import { ReportFormConfig, ReportFormQuery } from '../defs';
import { observer } from 'mobx-react-lite';

interface GameFooterProps {
  reportForm: ReportFormConfig;
  onSubmit: (query: ReportFormQuery) => void;
}

export const GameFooter: React.FunctionComponent<GameFooterProps> = observer(
  ({ reportForm, onSubmit }) => {
    return <ReportForm reportForm={reportForm} onSubmit={onSubmit} />;
  },
);
