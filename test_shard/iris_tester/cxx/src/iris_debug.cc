#include "iris_debug.h"
#include "fake_irtcengine.hpp"
#include "iris_cxx_api.h"
#include "iris_rtc_engine.h"

#include <map>
#include <set>
#include <string>

using namespace std;
using namespace agora::rtc;
using namespace agora::iris::rtc;

#define MOCK_FLAG_NONE 0
#define MOCK_FLAG_RETCODE 1
#define MOCK_FLAG_RESULT 2

struct IrisApiParam
{
  int flags;
  int retcode;
  std::string result;
};

static std::map<std::string, IrisApiParam> g_mapMockApis;
static std::set<std::string> g_setApiRecord;
static FakeIRtcEngine g_fakeRtcEngine;

static string genApiCallhash(ApiParam *apiParam)
{
  string callhash = std::string(apiParam->event) + apiParam->data;
  for (int i = 0; i < apiParam->buffer_count; i++)
  {
    uint64_t val = (uint64_t)apiParam->buffer[i];
    callhash.append("_" + std::to_string(val));
  }
  return callhash;
}

class IrisDebugApiEngine : public IrisApiEngine
{
public:
  IrisDebugApiEngine(IrisApiEngine *proxy)
  {
    if (proxy == nullptr)
      proxy_ = new IrisApiEngine();
    else
      proxy_ = proxy;
  }

  virtual int CallIrisApi(ApiParam *apiParam)
  {

    auto actualCallRet = proxy_->CallIrisApi(apiParam);

    // Return directly if CallIrisApi failed.
    if (actualCallRet < 0)
    {
      return actualCallRet;
    }

    string callhash = genApiCallhash(apiParam);

    g_setApiRecord.insert(callhash);

    auto it = g_mapMockApis.find(apiParam->event);
    if (it != g_mapMockApis.end())
    {
      int flags = it->second.flags;
      if (flags & MOCK_FLAG_RESULT)
      {
        memcpy(apiParam->result, it->second.result.c_str(),
               it->second.result.size());
      }

      if (flags & MOCK_FLAG_RETCODE)
      {
        return it->second.retcode;
      }
    }

    return actualCallRet;
  }

private:
  IrisApiEngine *proxy_;
};

void IRIS_CALL MockApiResult(const char *apiType, const char *param,
                             int paramLength)
{
  std::string data(param, paramLength);
  auto it = g_mapMockApis.find(apiType);
  if (it != g_mapMockApis.end())
  {
    IrisApiParam api = {0};
    g_mapMockApis[apiType] = api;
  }

  g_mapMockApis[apiType].flags |= MOCK_FLAG_RESULT;
  g_mapMockApis[apiType].result = data;
}

void IRIS_CALL MockApiReturnCode(const char *apiType, int code)
{
  auto it = g_mapMockApis.find(apiType);
  if (it != g_mapMockApis.end())
  {
    IrisApiParam api = {0};
    g_mapMockApis[apiType] = api;
  }

  g_mapMockApis[apiType].flags |= MOCK_FLAG_RETCODE;
  g_mapMockApis[apiType].retcode = code;
}

bool IRIS_CALL ExpectCalled(ApiParam *param)
{
  string callhash = genApiCallhash(param);
  if (g_setApiRecord.find(callhash) != g_setApiRecord.end())
  {
    return true;
  }

  return false;
}

IRIS_API IrisApiEnginePtr IRIS_CALL CreateDebugApiEngine()
{
  auto *fakeRtcEngine = &g_fakeRtcEngine;
  IrisApiEngine *engine = new IrisApiEngine(fakeRtcEngine);

  return engine;
}