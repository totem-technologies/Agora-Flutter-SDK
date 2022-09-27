#ifndef FAKE_IRTCENGINE_H_
#define FAKE_IRTCENGINE_H_

#include "fake_irtcengine_internal.hpp"

namespace agora
{
    namespace rtc
    {

        class FakeIRtcEngine : public FakeIRtcEngineInternal
        {
        public:
            IRtcEngineEventHandler *eventHandler;

            int queryInterface(INTERFACE_ID_TYPE iid, void **inter) override
            {
                return 0;
            }

            bool
            registerEventHandler(IRtcEngineEventHandler *eventHandler) override
            {
                this->eventHandler = eventHandler;
                return 0;
            }
            bool
            unregisterEventHandler(IRtcEngineEventHandler *eventHandler) override
            {
                this->eventHandler = nullptr;
                return 0;
            }
        };

    } // namespace rtc
} // namespace agora

#endif // FAKE_IRTCENGINE_H_