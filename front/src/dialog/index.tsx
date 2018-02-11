import * as React from 'react';
import * as ReactDOM from 'react-dom';

import {
    IConfirmDialog,
} from './defs';
import {
    ErrorBoundary,
} from '../util/error-boundary';

import {
    ConfirmDialog,
} from './component';

/**
 * Show a dialog.
 */
export function showConfirmDialog(d: IConfirmDialog): Promise<boolean> {
    return new Promise((resolve)=> {
        const dialog = (<ConfirmDialog
            {...d}
            onSelect={onSelect}
        />);

        // Add an area for showing dialog.
        const area = document.createElement('div');
        document.body.appendChild(area);

        ReactDOM.render(dialog, area);

        function onSelect(result: boolean): void {
            // clean up the dialog.
            ReactDOM.unmountComponentAtNode(area);
            document.body.removeChild(area);

            resolve(result);
        }
    });
}
