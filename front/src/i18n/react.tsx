import * as i18next from 'i18next';
import * as React from 'react';

export interface IPropI18n {
    children: (t: i18next.TranslationFunction)=> React.ReactNode;
    i18n: i18next.i18n;
    // Namespace selected for i18n instance.
    namespace?: string;
}
/**
 * Give render props a `t`.
 */
export class I18n extends React.Component<IPropI18n, {}> {
    constructor(props: IPropI18n) {
        super(props);

        this.rerender = this.rerender.bind(this);
    }
    public componentDidMount() {
        const {
            i18n,
        } = this.props;
        i18n.on('languageChanged', this.rerender);
    }
    public componentWillUnmount() {
        const {
            i18n,
        } = this.props;
        i18n.off('languageChanged', this.rerender);
    }
    public render() {
        const {
            children,
            i18n,
            namespace,
        } = this.props;
        const t = 
            namespace ?
            i18n.getFixedT(null, namespace) :
            i18n.t.bind(i18n);
        return children(t);
    }

    protected rerender() {
        this.forceUpdate();
    }
}
