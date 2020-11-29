import React from 'react';
import ReactDOM from 'react-dom';
import { i18n } from '../../i18n';
import { ReportFormConfig, ReportFormQuery } from '../game-view/defs';
import { Lobby } from './component';

interface IPlaceOptions {
  /**
   * i18n instance to use.
   */
  i18n: i18n;
  /**
   * A node to place the component to.
   */
  node: HTMLElement;
  /**
   * Data of report form.
   */
  reportForm: ReportFormConfig;
  /**
   * Handle a submit of report form.
   */
  onReportFormSubmit: (query: ReportFormQuery) => void;
}

interface IPlaceResult {
  unmount(): void;
}

/**
 * Place a game start control component.
 * @returns Unmount point with newly created store.
 */
export function place({
  i18n,
  node,
  reportForm,
  onReportFormSubmit,
}: IPlaceOptions): IPlaceResult {
  const com = (
    <Lobby
      i18n={i18n}
      reportForm={reportForm}
      onReportFormSubmit={onReportFormSubmit}
    />
  );

  ReactDOM.render(com, node);

  return {
    unmount: () => {
      ReactDOM.unmountComponentAtNode(node);
    },
  };
}
