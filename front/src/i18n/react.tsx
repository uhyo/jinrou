import * as i18next from 'i18next';
import * as React from 'react';

import {
    bind,
} from '../util/bind';

export interface IPropI18n {
    children: (t: i18next.TranslationFunction)=> React.ReactNode;
    i18n: i18next.i18n;
    // Namespace selected for i18n instance.
    namespace?: string;
}
export interface IStateI18n {
    t: i18next.TranslationFunction;
}
/**
 * Give render props a `t`.
 */
export class I18n extends React.PureComponent<IPropI18n, IStateI18n> {
    // Cache of t.
    constructor(props: IPropI18n) {
        super(props);
        // TODO waiting for React 16.3
        this.state = {
            t: this.makeT(),
        };
    }
    public componentDidMount() {
        const {
            i18n,
        } = this.props;
        i18n.on('languageChanged', this.renewT);
    }
    public componentWillUnmount() {
        const {
            i18n,
        } = this.props;
        i18n.off('languageChanged', this.renewT);
    }
    public render() {
        const {
            children,
        } = this.props;
        const {
            t,
        } = this.state;

        return children(t);
    }
    /**
     * Make a new translation function for current props.
     */
    protected makeT(): i18next.TranslationFunction {
        const {
            i18n,
            namespace,
        } = this.props;
        const t = 
            namespace ?
            i18n.getFixedT(null, namespace) :
            i18n.t.bind(i18n);
        return t;
    }
    /**
     * Remake a new t.
     */
    @bind
    protected renewT(): void {
        console.log('renew!');
        this.setState({
            t: this.makeT(),
        });
    }
}
