import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { IMessageDialog, IConfirmDialog } from './defs';
import { ErrorBoundary } from '../util/error-boundary';

import { MessageDialog, ConfirmDialog } from './component';

/**
 * Show a message dialog.
 */
export function showMessageDialog(d: IMessageDialog): Promise<void> {
  return showDialog((open, close) => {
    const dialog = <MessageDialog {...d} onClose={() => close(undefined)} />;

    open(dialog);
  });
}

/**
 * Show a confirmation dialog.
 */
export function showConfirmDialog(d: IConfirmDialog): Promise<boolean> {
  return showDialog((open, close) => {
    const dialog = <ConfirmDialog {...d} onSelect={close} />;

    open(dialog);
  });
}

/**
 * Inner function to show a dialog.
 */
function showDialog<T>(
  callback: (
    open: ((dialog: React.ReactElement<any>) => void),
    close: ((result: T) => void),
  ) => void,
): Promise<T> {
  return new Promise(resolve => {
    // Add an area for showing dialog.
    const area = document.createElement('div');
    document.body.appendChild(area);

    // show a dialog.
    const open = (dialog: React.ReactElement<any>) => {
      ReactDOM.render(dialog, area);
    };
    // clean up dialog.
    const close = (result: T) => {
      ReactDOM.unmountComponentAtNode(area);
      document.body.removeChild(area);
      resolve(result);
    };

    callback(open, close);
  });
}
