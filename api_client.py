# -*- coding: utf-8 -*-
"""
국토교통부 아파트 매매 실거래가 API 클라이언트
"""

import requests
import pandas as pd
import xml.etree.ElementTree as ET
from typing import Optional, List, Dict
from datetime import datetime
import os
from dotenv import load_dotenv
import urllib.parse
import time

# .env 파일 로드
load_dotenv()


def get_api_key_from_secrets() -> Optional[str]:
    """Streamlit Cloud Secrets에서 API 키 로드"""
    try:
        import streamlit as st
        return st.secrets.get("API_SERVICE_KEY")
    except (ImportError, KeyError, FileNotFoundError, AttributeError):
        return None


def get_api_key(provided_key: Optional[str] = None) -> Optional[str]:
    """
    API 키를 다양한 소스에서 로드
    우선순위: 직접 전달 > Streamlit Secrets > 환경변수
    """
    # 1. 직접 전달된 키
    if provided_key:
        return provided_key

    # 2. Streamlit Secrets (Cloud 환경)
    secrets_key = get_api_key_from_secrets()
    if secrets_key:
        return secrets_key

    # 3. 환경 변수 (로컬 환경)
    return os.getenv("API_SERVICE_KEY")


class ApartmentTradeAPI:
    """아파트 매매 실거래가 API 클라이언트"""

    BASE_URL = "https://apis.data.go.kr/1613000/RTMSDataSvcAptTrade/getRTMSDataSvcAptTrade"

    def __init__(self, service_key: Optional[str] = None):
        """
        API 클라이언트 초기화

        Args:
            service_key: API 인증키 (없으면 Streamlit Secrets 또는 환경변수에서 로드)
        """
        self.service_key = get_api_key(service_key)
        if not self.service_key:
            raise ValueError(
                "API 서비스키가 필요합니다. "
                "Streamlit Cloud: Secrets에 API_SERVICE_KEY를 설정하세요. "
                "로컬: .env 파일에 API_SERVICE_KEY를 설정하거나 직접 전달해주세요."
            )

    def fetch_data(
        self,
        region_code: str,
        deal_year_month: str,
        page_no: int = 1,
        num_of_rows: int = 1000
    ) -> Dict:
        """
        단일 요청으로 데이터 조회

        Args:
            region_code: 지역코드 (법정동코드 앞 5자리, 예: 11110)
            deal_year_month: 계약년월 (6자리, 예: 202401)
            page_no: 페이지 번호
            num_of_rows: 한 페이지 결과 수

        Returns:
            API 응답 데이터 (딕셔너리)
        """
        params = {
            "serviceKey": self.service_key,
            "LAWD_CD": region_code,
            "DEAL_YMD": deal_year_month,
            "pageNo": page_no,
            "numOfRows": num_of_rows,
        }

        try:
            response = requests.get(self.BASE_URL, params=params, timeout=30)
            response.raise_for_status()
            return self._parse_xml_response(response.text)
        except requests.exceptions.RequestException as e:
            return {"error": str(e), "items": [], "total_count": 0}

    def _parse_xml_response(self, xml_text: str) -> Dict:
        """XML 응답 파싱"""
        try:
            root = ET.fromstring(xml_text)

            # 결과 코드 확인
            header = root.find(".//header")
            if header is not None:
                result_code = header.findtext("resultCode", "")
                result_msg = header.findtext("resultMsg", "")

                if result_code != "00" and result_code != "000":
                    return {
                        "error": f"API 오류 [{result_code}]: {result_msg}",
                        "items": [],
                        "total_count": 0
                    }

            # 데이터 파싱
            items = []
            body = root.find(".//body")

            if body is not None:
                total_count = int(body.findtext("totalCount", "0"))

                for item in body.findall(".//item"):
                    item_data = {}
                    for child in item:
                        # 텍스트 값이 있으면 저장, 없으면 빈 문자열
                        item_data[child.tag] = child.text.strip() if child.text else ""
                    items.append(item_data)

                return {
                    "items": items,
                    "total_count": total_count,
                    "page_no": int(body.findtext("pageNo", "1")),
                    "num_of_rows": int(body.findtext("numOfRows", "10"))
                }

            return {"items": [], "total_count": 0}

        except ET.ParseError as e:
            return {"error": f"XML 파싱 오류: {str(e)}", "items": [], "total_count": 0}

    def fetch_all_pages(
        self,
        region_code: str,
        deal_year_month: str,
        progress_callback=None
    ) -> List[Dict]:
        """
        모든 페이지 데이터 조회

        Args:
            region_code: 지역코드
            deal_year_month: 계약년월
            progress_callback: 진행 상황 콜백 함수 (current, total)

        Returns:
            전체 거래 데이터 리스트
        """
        all_items = []
        page_no = 1
        num_of_rows = 1000

        # 첫 페이지 조회로 전체 건수 확인
        result = self.fetch_data(region_code, deal_year_month, page_no, num_of_rows)

        if "error" in result:
            return []

        all_items.extend(result.get("items", []))
        total_count = result.get("total_count", 0)

        if progress_callback:
            progress_callback(len(all_items), total_count)

        # 추가 페이지가 있으면 조회
        while len(all_items) < total_count:
            page_no += 1
            time.sleep(0.1)  # API 호출 간격 조절

            result = self.fetch_data(region_code, deal_year_month, page_no, num_of_rows)

            if "error" in result or not result.get("items"):
                break

            all_items.extend(result["items"])

            if progress_callback:
                progress_callback(len(all_items), total_count)

        return all_items

    def fetch_multiple_months(
        self,
        region_code: str,
        start_year_month: str,
        end_year_month: str,
        progress_callback=None
    ) -> pd.DataFrame:
        """
        여러 달의 데이터를 조회하여 DataFrame으로 반환

        Args:
            region_code: 지역코드
            start_year_month: 시작 년월 (예: 202401)
            end_year_month: 종료 년월 (예: 202412)
            progress_callback: 진행 상황 콜백 함수 (current_month, total_months, current_items)

        Returns:
            거래 데이터 DataFrame
        """
        # 년월 리스트 생성
        months = self._generate_month_range(start_year_month, end_year_month)
        all_items = []

        for idx, month in enumerate(months):
            if progress_callback:
                progress_callback(idx + 1, len(months), len(all_items))

            items = self.fetch_all_pages(region_code, month)
            all_items.extend(items)

            time.sleep(0.2)  # API 호출 간격 조절

        if not all_items:
            return pd.DataFrame()

        # DataFrame 변환 및 전처리
        df = pd.DataFrame(all_items)
        df = self._preprocess_dataframe(df)

        return df

    def _generate_month_range(self, start: str, end: str) -> List[str]:
        """시작~종료 년월 사이의 모든 년월 리스트 생성"""
        start_year = int(start[:4])
        start_month = int(start[4:])
        end_year = int(end[:4])
        end_month = int(end[4:])

        months = []
        year, month = start_year, start_month

        while (year < end_year) or (year == end_year and month <= end_month):
            months.append(f"{year}{month:02d}")
            month += 1
            if month > 12:
                month = 1
                year += 1

        return months

    def _preprocess_dataframe(self, df: pd.DataFrame) -> pd.DataFrame:
        """DataFrame 전처리"""
        if df.empty:
            return df

        # 컬럼명 매핑 (API 응답 -> 기존 앱 형식)
        column_mapping = {
            "sggCd": "지역코드",
            "umdNm": "법정동",
            "aptNm": "단지명",
            "jibun": "지번",
            "excluUseAr": "전용면적(㎡)",
            "dealYear": "계약년도",
            "dealMonth": "계약월",
            "dealDay": "계약일",
            "dealAmount": "거래금액(만원)",
            "floor": "층",
            "buildYear": "건축년도",
            "cdealType": "해제여부",
            "cdealDay": "해제사유발생일",
            "dealingGbn": "거래유형",
            "estateAgentSggNm": "중개사소재지",
            "rgstDate": "등기일자",
            "aptDong": "동",
            "slerGbn": "매도자",
            "buyerGbn": "매수자",
            "landLeaseholdGbn": "토지임대부여부",
        }

        # 존재하는 컬럼만 매핑
        rename_dict = {k: v for k, v in column_mapping.items() if k in df.columns}
        df = df.rename(columns=rename_dict)

        # 데이터 타입 변환
        if "거래금액(만원)" in df.columns:
            df["거래금액(만원)"] = df["거래금액(만원)"].str.replace(",", "").astype(int)

        if "전용면적(㎡)" in df.columns:
            df["전용면적(㎡)"] = pd.to_numeric(df["전용면적(㎡)"], errors="coerce")

        if "층" in df.columns:
            df["층"] = pd.to_numeric(df["층"], errors="coerce")

        if "건축년도" in df.columns:
            df["건축년도"] = pd.to_numeric(df["건축년도"], errors="coerce")

        # 계약년월 생성 (기존 앱 형식과 호환)
        if all(col in df.columns for col in ["계약년도", "계약월"]):
            df["계약년월"] = df["계약년도"].astype(str) + df["계약월"].astype(str).str.zfill(2)
            df["계약년월"] = pd.to_numeric(df["계약년월"], errors="coerce")

        # 시군구 컬럼 생성 (기존 앱 호환)
        if "법정동" in df.columns:
            df["시군구"] = df.get("지역코드", "") + " " + df["법정동"]

        # NO 컬럼 추가 (인덱스)
        df["NO"] = range(1, len(df) + 1)

        return df


def test_api_connection(service_key: Optional[str] = None) -> Dict:
    """
    API 연결 테스트

    Args:
        service_key: API 서비스키

    Returns:
        테스트 결과 딕셔너리
    """
    try:
        api = ApartmentTradeAPI(service_key)
        # 서울 종로구 최근 월 데이터로 테스트
        current_date = datetime.now()
        test_month = f"{current_date.year}{current_date.month:02d}"

        result = api.fetch_data("11110", test_month, page_no=1, num_of_rows=1)

        if "error" in result:
            return {"success": False, "message": result["error"]}

        return {
            "success": True,
            "message": f"API 연결 성공! (총 {result.get('total_count', 0)}건의 데이터)",
            "total_count": result.get("total_count", 0)
        }
    except Exception as e:
        return {"success": False, "message": str(e)}
